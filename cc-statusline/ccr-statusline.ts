#!/usr/bin/env npx tsx

/**
 * Claude Code Router cost tracking statusline
 *
 * Supports: OpenRouter (live pricing) and DashScope (LiteLLM live pricing, CNY fallback)
 * Displays: Provider | Model | Input/Output price | Session cost
 */

import { existsSync, readFileSync, writeFileSync, mkdirSync, renameSync, unlinkSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

// ── Types ──

interface StatuslineInput {
  session_id: string;
  transcript_path: string;
}

interface TokenUsage {
  input_tokens?: number;
  output_tokens?: number;
  cache_creation_input_tokens?: number;
  cache_read_input_tokens?: number;
}

interface TranscriptMessage {
  message?: {
    id?: string;
    model?: string;
    usage?: TokenUsage;
  };
}

interface ProviderConfig {
  name: string;
  api_base_url: string;
  api_key: string;
  models: string[];
}

interface CCRConfig {
  Providers: ProviderConfig[];
  Router: {
    default: string;
    background?: string;
    think?: string;
    longContext?: string;
    webSearch?: string;
    image?: string;
  };
}

interface ModelPricing {
  input_price: number;  // per million tokens, USD
  output_price: number; // per million tokens, USD
}

interface PricingCache {
  fetched_at: number;
  prices: Record<string, ModelPricing>;
}

interface MessageCost {
  id: string;
  model: string;
  provider: string;
  input_tokens: number;
  output_tokens: number;
  cost: number; // USD cost for this message
}

interface SessionState {
  session_id: string;
  total_cost: number;
  last_model: string;
  last_provider: string;
  seen_messages: string[];
  message_count: number;
  // Per-message cost tracking for accurate total
  message_costs: MessageCost[];
  // Cached pricing for current model display
  cached_pricing?: { input_price: number; output_price: number };
  cached_pricing_model?: string;
  // Track Router config's default (provider:model) for resume detection
  router_default_config?: string;
  // Deferred billing reset: set on config change, executed on first new message
  pending_billing_reset?: boolean;
}

// ── Remote pricing source for DashScope ──
const LITELLM_PRICING_URL = 'https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json';

// Hardcoded CNY fallback pricing (China mainland, lowest tier)
// Source: https://help.aliyun.com/zh/model-studio/model-pricing
// Only used when remote LiteLLM pricing fetch fails
const DASHSCOPE_CNY_FALLBACK_PRICING: Record<string, { input: number; output: number }> = {
  'qwen3-max':             { input: 2.5,  output: 10 },
  'qwen3-max-2026-01-23':  { input: 2.5,  output: 10 },
  'qwen-max':              { input: 2.4,  output: 9.6 },
  'qwen-plus':             { input: 0.8,  output: 2 },
  'qwen-turbo':            { input: 0.3,  output: 0.6 },
  'qwen-flash':            { input: 0.15, output: 1.5 },
  'qwen-long':             { input: 0.5,  output: 2 },
  'qwq-plus':              { input: 1.6,  output: 4 },
  'qwen3-coder-plus':      { input: 0.8,  output: 2 }, // subscription model, estimated
  // Kimi models via DashScope (Source: https://help.aliyun.com/zh/model-studio/kimi-models)
  'kimi-k2.5':             { input: 2.0,  output: 8.0 },
  'kimi-k2-thinking':      { input: 2.0,  output: 8.0 },
};

// Direct Kimi API pricing (when using kimi alias, not via DashScope)
// Source: https://platform.moonshot.cn/docs/pricing
const KIMI_DIRECT_PRICING: Record<string, { input: number; output: number }> = {
  'kimi-k2.5':        { input: 2.0,  output: 8.0 },   // CNY per million tokens
  'kimi-k2-thinking': { input: 2.0,  output: 8.0 },   // CNY per million tokens
  'kimi-k2':          { input: 2.0,  output: 8.0 },   // CNY per million tokens
  'kimi-k1.5':        { input: 2.0,  output: 8.0 },   // CNY per million tokens
  'kimi-latest':      { input: 2.0,  output: 8.0 },   // Alias, same as k2.5
};

const CNY_TO_USD = 0.137; // approximate conversion rate
const PRICING_CACHE_TTL_MS = 6 * 60 * 60 * 1000; // 6 hours

// ── Config & Provider helpers ──

/**
 * Detect provider directly from environment variables.
 * This is used when claude-code-router config is not available
 * but user has set ANTHROPIC_BASE_URL (e.g., via kimi alias).
 */
function detectProviderFromEnv(): { name: string; baseUrl: string } | null {
  const baseUrl = process.env.ANTHROPIC_BASE_URL || '';

  if (baseUrl.includes('kimi.com')) {
    return { name: 'kimi', baseUrl };
  }
  if (baseUrl.includes('openrouter.ai')) {
    return { name: 'openrouter', baseUrl };
  }
  if (baseUrl.includes('dashscope') || baseUrl.includes('aliyun')) {
    return { name: 'dashscope', baseUrl };
  }
  // Default anthropic
  if (!baseUrl || baseUrl.includes('anthropic.com')) {
    return { name: 'anthropic', baseUrl: baseUrl || 'https://api.anthropic.com' };
  }

  return null;
}

function loadCCRConfig(): CCRConfig | null {
  try {
    const configPath = join(homedir(), '.claude-code-router', 'config.json');
    if (!existsSync(configPath)) return null;
    return JSON.parse(readFileSync(configPath, 'utf-8'));
  } catch {
    return null;
  }
}

function getProviderForModel(config: CCRConfig | null, model: string): ProviderConfig | null {
  if (!config) return null;

  // First check if the model matches the Router default provider
  const routerDefault = parseRouterDefault(config);
  if (routerDefault) {
    const defaultProvider = config.Providers.find(p => p.name === routerDefault.provider);
    if (defaultProvider) {
      // Check if default provider has this model
      if (defaultProvider.models.includes(model)) return defaultProvider;
      for (const pm of defaultProvider.models) {
        if (model.includes(pm) || pm.includes(model)) return defaultProvider;
      }
      // Also check if model contains the default provider's model name
      // e.g., model="moonshotai/kimi-k2.5" and routerDefault.model="kimi-k2.5"
      if (model.includes(routerDefault.model)) return defaultProvider;
    }
  }

  // Fall back to checking all providers
  for (const provider of config.Providers) {
    if (provider.models.includes(model)) return provider;
    for (const pm of provider.models) {
      if (model.includes(pm) || pm.includes(model)) return provider;
    }
  }
  return null;
}

function parseRouterDefault(config: CCRConfig): { provider: string; model: string } | null {
  const defaultRoute = config.Router?.default;
  if (!defaultRoute) return null;

  const parts = defaultRoute.split(',').map(s => s.trim());
  if (parts.length === 0) return null;

  const providerName = parts[0];
  let model = parts.length > 1 ? parts[1] : '';

  if (!model) {
    const provider = config.Providers.find(p => p.name === providerName);
    if (provider?.models.length) model = provider.models[0];
  }

  return model ? { provider: providerName, model } : null;
}

function extractModelName(fullModel: string): string {
  // Remove provider prefix (e.g., "anthropic/claude-3-opus" -> "claude-3-opus")
  const withoutPrefix = fullModel.replace(/^[^/]+\//, '');
  // Remove date suffix: support both YYYYMMDD and YYYY-MM-DD formats
  return withoutPrefix.replace(/(-\d{4}-\d{2}-\d{2}|-\d{8})$/, '');
}

// ── Pricing: fetch & cache ──

function getPricingCachePath(): string {
  return join(homedir(), '.claude', 'ccr-cost', 'pricing-cache.json');
}

function loadPricingCache(): PricingCache | null {
  try {
    const cachePath = getPricingCachePath();
    if (!existsSync(cachePath)) return null;
    const data: PricingCache = JSON.parse(readFileSync(cachePath, 'utf-8'));
    if (Date.now() - data.fetched_at > PRICING_CACHE_TTL_MS) return null;
    return data;
  } catch {
    return null;
  }
}

function savePricingCache(cache: PricingCache): void {
  try {
    const dir = join(homedir(), '.claude', 'ccr-cost');
    mkdirSync(dir, { recursive: true });
    const cachePath = getPricingCachePath();
    const tmpPath = `${cachePath}.tmp`;
    writeFileSync(tmpPath, JSON.stringify(cache));
    renameSync(tmpPath, cachePath);
  } catch {
    // non-critical
  }
}

async function fetchOpenRouterPricing(apiKey: string): Promise<Record<string, ModelPricing>> {
  try {
    const res = await fetch('https://openrouter.ai/api/v1/models', {
      headers: { Authorization: `Bearer ${apiKey}` },
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return {};

    const json = await res.json();
    const prices: Record<string, ModelPricing> = {};

    for (const model of json.data ?? []) {
      const pricing = model.pricing;
      if (!pricing) continue;
      // OpenRouter returns per-token price as string
      const promptPerToken = parseFloat(pricing.prompt ?? '0');
      const completionPerToken = parseFloat(pricing.completion ?? '0');
      prices[model.id] = {
        input_price: promptPerToken * 1_000_000,
        output_price: completionPerToken * 1_000_000,
      };
    }
    return prices;
  } catch {
    return {};
  }
}

// ── Kimi dynamic pricing via LiteLLM ──

function getKimiPricingCachePath(): string {
  return join(homedir(), '.claude', 'ccr-cost', 'kimi-pricing-cache.json');
}

function loadKimiPricingCache(): PricingCache | null {
  try {
    const cachePath = getKimiPricingCachePath();
    if (!existsSync(cachePath)) return null;
    const data: PricingCache = JSON.parse(readFileSync(cachePath, 'utf-8'));
    if (Date.now() - data.fetched_at > PRICING_CACHE_TTL_MS) return null;
    return data;
  } catch {
    return null;
  }
}

function saveKimiPricingCache(cache: PricingCache): void {
  try {
    const dir = join(homedir(), '.claude', 'ccr-cost');
    mkdirSync(dir, { recursive: true });
    const cachePath = getKimiPricingCachePath();
    const tmpPath = `${cachePath}.tmp`;
    writeFileSync(tmpPath, JSON.stringify(cache));
    renameSync(tmpPath, cachePath);
  } catch {
    // non-critical
  }
}

async function fetchKimiPricingFromLiteLLM(): Promise<Record<string, ModelPricing>> {
  try {
    const res = await fetch(LITELLM_PRICING_URL, {
      signal: AbortSignal.timeout(10000),
    });
    if (!res.ok) return {};

    const json = await res.json();
    const prices: Record<string, ModelPricing> = {};

    for (const [key, value] of Object.entries(json)) {
      const entry = value as Record<string, unknown>;
      const modelId = key.toLowerCase();

      // Match kimi models from various providers
      if (!modelId.includes('kimi')) continue;

      const inputCost = entry.input_cost_per_token as number;
      const outputCost = entry.output_cost_per_token as number;
      if (!inputCost && !outputCost) continue;

      // Extract model name (e.g., "bedrock/us-east-1/moonshotai.kimi-k2.5" -> "kimi-k2.5")
      let modelName = key;
      if (key.includes('moonshotai.')) {
        modelName = key.split('moonshotai.').pop() || key;
      } else if (key.includes('/')) {
        modelName = key.split('/').pop() || key;
      }

      prices[modelName] = {
        input_price: (inputCost || 0) * 1_000_000,
        output_price: (outputCost || 0) * 1_000_000,
      };
    }
    return prices;
  } catch {
    return {};
  }
}

// ── DashScope dynamic pricing via LiteLLM ──

function getDashScopePricingCachePath(): string {
  return join(homedir(), '.claude', 'ccr-cost', 'dashscope-pricing-cache.json');
}

function loadDashScopePricingCache(): PricingCache | null {
  try {
    const cachePath = getDashScopePricingCachePath();
    if (!existsSync(cachePath)) return null;
    const data: PricingCache = JSON.parse(readFileSync(cachePath, 'utf-8'));
    if (Date.now() - data.fetched_at > PRICING_CACHE_TTL_MS) return null;
    return data;
  } catch {
    return null;
  }
}

function saveDashScopePricingCache(cache: PricingCache): void {
  try {
    const dir = join(homedir(), '.claude', 'ccr-cost');
    mkdirSync(dir, { recursive: true });
    const cachePath = getDashScopePricingCachePath();
    const tmpPath = `${cachePath}.tmp`;
    writeFileSync(tmpPath, JSON.stringify(cache));
    renameSync(tmpPath, cachePath);
  } catch {
    // non-critical
  }
}

async function fetchDashScopePricingFromLiteLLM(): Promise<Record<string, ModelPricing>> {
  try {
    const res = await fetch(LITELLM_PRICING_URL, {
      signal: AbortSignal.timeout(10000),
    });
    if (!res.ok) return {};

    const json = await res.json();
    const prices: Record<string, ModelPricing> = {};

    for (const [key, value] of Object.entries(json)) {
      const entry = value as Record<string, unknown>;
      const provider = entry.litellm_provider as string;
      if (!provider?.startsWith('dashscope')) continue;
      if (entry.mode !== 'chat') continue;

      const inputCost = entry.input_cost_per_token as number;
      const outputCost = entry.output_cost_per_token as number;
      if (!inputCost && !outputCost) continue;

      // Key: "dashscope/qwen-max" → model name only
      const modelName = key.includes('/') ? key.split('/').slice(1).join('/') : key;
      prices[modelName] = {
        input_price: (inputCost || 0) * 1_000_000,
        output_price: (outputCost || 0) * 1_000_000,
      };
    }
    return prices;
  } catch {
    return {};
  }
}

function getDashScopeFallbackPricing(model: string): ModelPricing {
  // Remove provider prefix if present
  const cleanModel = model.replace(/^[^/]+\//, '');

  // Try exact match
  const cnPrice = DASHSCOPE_CNY_FALLBACK_PRICING[cleanModel];
  if (cnPrice) {
    return {
      input_price: +(cnPrice.input * CNY_TO_USD).toFixed(4),
      output_price: +(cnPrice.output * CNY_TO_USD).toFixed(4),
    };
  }

  // Try base model name match (strip date suffix: both YYYYMMDD and YYYY-MM-DD formats)
  const baseModel = cleanModel.replace(/(-\d{4}-\d{2}-\d{2}|-\d{8})$/, '');
  const basePrice = DASHSCOPE_CNY_FALLBACK_PRICING[baseModel];
  if (basePrice) {
    return {
      input_price: +(basePrice.input * CNY_TO_USD).toFixed(4),
      output_price: +(basePrice.output * CNY_TO_USD).toFixed(4),
    };
  }

  // Unknown
  return { input_price: 0, output_price: 0 };
}

async function getKimiPricing(model: string): Promise<ModelPricing> {
  const cleanModel = model.replace(/^[^/]+\//, '');
  const baseModel = cleanModel.replace(/(-\d{4}-\d{2}-\d{2}|-\d{8})$/, '');

  // Try Kimi pricing cache (from LiteLLM)
  const kimiCache = loadKimiPricingCache();
  if (kimiCache) {
    const found = kimiCache.prices[cleanModel] || kimiCache.prices[baseModel];
    if (found) return found;
  }

  // Fetch live from LiteLLM's pricing database
  const livePrices = await fetchKimiPricingFromLiteLLM();
  if (Object.keys(livePrices).length > 0) {
    saveKimiPricingCache({ fetched_at: Date.now(), prices: livePrices });
    const found = livePrices[cleanModel] || livePrices[baseModel];
    if (found) return found;
  }

  // Fallback to hardcoded CNY pricing (Kimi official pricing)
  const cnPrice = KIMI_DIRECT_PRICING[cleanModel] || KIMI_DIRECT_PRICING[baseModel];
  if (cnPrice) {
    return {
      input_price: +(cnPrice.input * CNY_TO_USD).toFixed(4),
      output_price: +(cnPrice.output * CNY_TO_USD).toFixed(4),
    };
  }

  // Default to k2.5 pricing if model name contains kimi
  if (cleanModel.includes('kimi')) {
    return {
      input_price: +(2.0 * CNY_TO_USD).toFixed(4),
      output_price: +(8.0 * CNY_TO_USD).toFixed(4),
    };
  }

  return { input_price: 0, output_price: 0 };
}

async function resolvePricing(
  config: CCRConfig | null,
  model: string,
  providerName: string,
): Promise<ModelPricing> {
  // Direct Kimi API (not via DashScope)
  if (providerName === 'kimi') {
    return getKimiPricing(model);
  }

  if (providerName === 'dashscope') {
    const cleanModel = model.replace(/^[^/]+\//, '');
    const baseModel = cleanModel.replace(/(-\d{4}-\d{2}-\d{2}|-\d{8})$/, '');

    // Try DashScope pricing cache (from LiteLLM)
    const dsCache = loadDashScopePricingCache();
    if (dsCache) {
      const found = dsCache.prices[cleanModel] || dsCache.prices[baseModel];
      if (found) return found;
    }

    // Fetch live from LiteLLM's pricing database
    const livePrices = await fetchDashScopePricingFromLiteLLM();
    if (Object.keys(livePrices).length > 0) {
      saveDashScopePricingCache({ fetched_at: Date.now(), prices: livePrices });
      const found = livePrices[cleanModel] || livePrices[baseModel];
      if (found) return found;
    }

    // Fallback to hardcoded CNY pricing
    return getDashScopeFallbackPricing(model);
  }

  // OpenRouter: try cache first, then fetch live
  const cache = loadPricingCache();
  if (cache?.prices[model]) {
    return cache.prices[model];
  }

  // Fetch fresh data
  const provider = config?.Providers.find(p => p.name === providerName);
  const apiKey = provider?.api_key ?? '';
  const livePrices = await fetchOpenRouterPricing(apiKey);

  if (Object.keys(livePrices).length > 0) {
    savePricingCache({ fetched_at: Date.now(), prices: livePrices });
    if (livePrices[model]) return livePrices[model];
  }

  // Final fallback
  return { input_price: 0, output_price: 0 };
}

// ── State management ──

function loadState(statePath: string, sessionId: string): SessionState {
  const def: SessionState = {
    session_id: sessionId,
    total_cost: 0,
    last_model: '', last_provider: '',
    seen_messages: [], message_count: 0,
    message_costs: [],
  };
  if (!existsSync(statePath)) return def;
  try {
    const parsed = JSON.parse(readFileSync(statePath, 'utf-8'));
    return { ...def, ...parsed, session_id: sessionId,
      seen_messages: Array.isArray(parsed.seen_messages) ? parsed.seen_messages : [],
      message_costs: Array.isArray(parsed.message_costs) ? parsed.message_costs : [],
    };
  } catch {
    return def;
  }
}

// Maximum entries to keep in state (prevent unbounded growth)
const MAX_STATE_ENTRIES = 1000;

function saveState(statePath: string, state: SessionState): void {
  try {
    // Limit arrays to prevent unbounded growth
    if (state.seen_messages.length > MAX_STATE_ENTRIES) {
      state.seen_messages = state.seen_messages.slice(-MAX_STATE_ENTRIES);
    }
    if (state.message_costs.length > MAX_STATE_ENTRIES) {
      // Keep most recent message costs and recalculate total
      state.message_costs = state.message_costs.slice(-MAX_STATE_ENTRIES);
      state.total_cost = state.message_costs.reduce((sum, m) => sum + m.cost, 0);
    }
    // Atomic write: write to temp file then rename
    const tmpPath = `${statePath}.tmp`;
    writeFileSync(tmpPath, JSON.stringify(state));
    renameSync(tmpPath, statePath);
  } catch {}
}

// ── Transcript parsing ──
// Transcript is streaming: same message ID appears multiple times,
// only the last occurrence has real usage data.

interface AggregatedMessage {
  id: string;
  model: string;
  input_tokens: number;
  output_tokens: number;
}

function parseTranscript(transcriptPath: string): AggregatedMessage[] {
  try {
    if (!existsSync(transcriptPath)) return [];
    const content = readFileSync(transcriptPath, 'utf-8');

    // Collect best usage per message ID (last write wins)
    const byId = new Map<string, AggregatedMessage>();

    for (const line of content.split('\n')) {
      if (!line.trim()) continue;
      try {
        const entry = JSON.parse(line);
        const msg = entry.message;
        if (!msg?.id) continue;

        const usage = msg.usage;
        const inTok = (usage?.input_tokens || 0) +
          (usage?.cache_creation_input_tokens || 0) +
          (usage?.cache_read_input_tokens || 0);
        const outTok = usage?.output_tokens || 0;

        const existing = byId.get(msg.id);
        const existingTotal = existing ? existing.input_tokens + existing.output_tokens : 0;

        // Keep the entry with the largest token count (the final streaming chunk)
        if (!existing || (inTok + outTok) >= existingTotal) {
          byId.set(msg.id, {
            id: msg.id,
            model: msg.model || existing?.model || '',
            input_tokens: inTok,
            output_tokens: outTok,
          });
        }
      } catch {}
    }

    return [...byId.values()];
  } catch {
    return [];
  }
}

// ── Main ──

async function main(): Promise<void> {
  try {
    let inputData = '';
    for await (const chunk of process.stdin) { inputData += chunk; }

    const input: StatuslineInput = JSON.parse(inputData);
    const { session_id, transcript_path } = input;
    if (!session_id || !transcript_path) {
      process.stdout.write('Invalid input');
      return;
    }

    const config = loadCCRConfig();
    const envProvider = detectProviderFromEnv();

    // Support direct provider via environment (e.g., kimi alias)
    // When envProvider is detected (e.g., kimi), it takes priority over CCR config
    if (!config && !envProvider) {
      process.stdout.write('CCR config not found');
      return;
    }

    const stateDir = join(homedir(), '.claude', 'ccr-cost');
    try { mkdirSync(stateDir, { recursive: true }); } catch {}
    const statePath = join(stateDir, `${session_id}.json`);
    const state = loadState(statePath, session_id);

    // Parse transcript early (needed for both reset detection and message processing)
    const messages = parseTranscript(transcript_path);
    const seenSet = new Set(state.seen_messages);
    const hasUnseenMessages = messages.some(m => !seenSet.has(m.id));

    // Detect session resume with different model → deferred billing reset
    const routerDefault = config ? parseRouterDefault(config) : null;
    const envDefault = envProvider ? { provider: envProvider.name, model: '' } : null;
    const effectiveDefault = routerDefault || envDefault;
    const currentConfig = effectiveDefault
      ? `${effectiveDefault.provider}:${effectiveDefault.model}` : '';
    let costWasReset = false;
    const prevPendingReset = !!state.pending_billing_reset;
    const configChanged = !!(
      state.router_default_config &&
      state.router_default_config !== currentConfig
    );

    // Phase 1: config changed → set pending flag only if no new messages yet
    if (configChanged) {
      if (!hasUnseenMessages) {
        // No new messages yet → likely a resume, defer reset until first message
        state.pending_billing_reset = true;
      } else {
        // New messages already exist → mid-session switch, cancel any pending
        state.pending_billing_reset = false;
      }
    }
    state.router_default_config = currentConfig;

    // Phase 2: execute deferred reset when first new message arrives
    if (state.pending_billing_reset && hasUnseenMessages) {
      // Keep seen_messages so old transcript entries aren't reprocessed
      state.total_cost = 0;
      state.message_costs = [];
      state.message_count = 0;
      state.cached_pricing = undefined;
      state.cached_pricing_model = undefined;
      state.last_model = '';
      state.last_provider = '';
      state.pending_billing_reset = false;
      costWasReset = true;
    }
    const processedCosts = new Map<string, MessageCost>();
    for (const mc of state.message_costs) processedCosts.set(mc.id, mc);
    let hasNewData = false;

    // Pricing cache for this batch to avoid repeated API calls
    const pricingCache = new Map<string, ModelPricing>();

    for (const msg of messages) {
      if (seenSet.has(msg.id)) continue;

      // Determine provider for this message
      // Priority: 1. Env-detected provider (e.g., kimi alias), 2. CCR config provider
      let msgProvider = state.last_provider;
      if (msg.model) {
        state.last_model = msg.model;
        if (envProvider) {
          // Use env-detected provider (takes priority)
          state.last_provider = envProvider.name;
          msgProvider = envProvider.name;
        } else if (config) {
          const prov = getProviderForModel(config, msg.model);
          if (prov) {
            state.last_provider = prov.name;
            msgProvider = prov.name;
          }
        }
      }

      // Calculate cost for this specific message using its model's pricing
      let msgCost = 0;
      if (msg.input_tokens > 0 || msg.output_tokens > 0) {
        const modelKey = `${msgProvider}:${msg.model || state.last_model}`;
        let msgPricing = pricingCache.get(modelKey);
        if (!msgPricing) {
          msgPricing = await resolvePricing(config, msg.model || state.last_model, msgProvider);
          pricingCache.set(modelKey, msgPricing);
        }
        msgCost =
          (msg.input_tokens / 1_000_000) * msgPricing.input_price +
          (msg.output_tokens / 1_000_000) * msgPricing.output_price;
      }

      // Store per-message cost
      processedCosts.set(msg.id, {
        id: msg.id,
        model: msg.model || state.last_model,
        provider: msgProvider,
        input_tokens: msg.input_tokens,
        output_tokens: msg.output_tokens,
        cost: msgCost,
      });

      seenSet.add(msg.id);
      state.message_count++;
      hasNewData = true;
    }

    state.seen_messages = [...seenSet];
    state.message_costs = [...processedCosts.values()];

    // Recalculate total cost from all message costs
    state.total_cost = state.message_costs.reduce((sum, m) => sum + m.cost, 0);

    // Infer from Router config or env provider if no model found
    // Priority: env provider takes precedence when detected
    if (!state.last_model) {
      if (envProvider) {
        state.last_provider = envProvider.name;
      } else if (routerDefault) {
        state.last_model = routerDefault.model;
        state.last_provider = routerDefault.provider;
      }
    } else if (envProvider) {
      // If we have a model but env provider is detected, use env provider
      state.last_provider = envProvider.name;
    }

    // Resolve pricing for current model display only
    let pricing: ModelPricing;
    if (state.cached_pricing && state.cached_pricing_model === state.last_model) {
      pricing = state.cached_pricing;
    } else {
      pricing = await resolvePricing(config, state.last_model, state.last_provider);
      state.cached_pricing = pricing;
      state.cached_pricing_model = state.last_model;
    }

    const pendingFlagChanged = prevPendingReset !== !!state.pending_billing_reset;
    if (hasNewData || costWasReset || pendingFlagChanged) saveState(statePath, state);

    // ── Format output ──

    const providerStr = state.last_provider || envProvider?.name || '?';
    const modelStr = extractModelName(state.last_model || '?');

    // Format pricing
    const fmtPrice = (p: number): string => {
      if (p === 0) return '?';
      if (p % 1 === 0) return p.toString();
      return p.toFixed(2).replace(/0+$/, '').replace(/\.$/, '');
    };
    const pricingStr = `$${fmtPrice(pricing.input_price)}/$${fmtPrice(pricing.output_price)}/M`;

    // Format cost - show cost even if 0 when we have pricing info
    let costStr: string;
    const hasValidPricing = pricing.input_price > 0 || pricing.output_price > 0;
    if (state.total_cost > 0) {
      costStr = state.total_cost < 0.01
        ? `${(state.total_cost * 100).toFixed(2)}$`
        : `$${state.total_cost.toFixed(3)}`;
    } else if (hasValidPricing && state.message_count > 0) {
      // We have pricing but cost is 0, show $0 instead of msg count
      costStr = '$0.000';
    } else {
      costStr = `${state.message_count}msg`;
    }

    // Status indicator
    const indicator = hasNewData ? ` \x1b[32m●\x1b[0m` : '';

    process.stdout.write(`${providerStr} | ${modelStr} | ${pricingStr} | ${costStr}${indicator}`);
  } catch (err) {
    process.stdout.write(`error: ${(err as Error).message}`);
  }
}

main().catch(err => process.stdout.write(`error: ${err.message}`));
