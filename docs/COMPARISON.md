# Linnix vs Prometheus, Datadog, and Elastic APM

Linnix pairs eBPF-native process telemetry with an on-device AI reasoner. It is not a drop-in replacement for time-series or APM suites, but it fills the gap between raw metrics and actionable explanations. The matrix below highlights where each tool shines.

## Feature Comparison

| Capability | Linnix (OSS) | Prometheus + Grafana | Datadog | Elastic APM |
|------------|--------------|----------------------|---------|-------------|
| Primary data source | eBPF fork/exec/exit stream + CPU/RSS samples | Exporters / scraping | Host + language agents | Language agents + Beats |
| Setup time | 5 minutes (`setup-llm.sh`) | 2-3 hours (server + exporters) | ~30 minutes (agent rollout) | 1-2 hours (APM + Fleet) |
| Instrumentation effort | Zero (kernel hooks) | Manual per-service metrics | Agents per host + code hooks | Code changes + ingest pipeline |
| CPU overhead | <1% (event-driven eBPF) | 2-5% (scrapers & exporters) | 5-15% (always-on agent) | 10-20% (instrumented services) |
| AI insights | Built-in natural language reasoning | Not available | Paid add-ons only | Not available |
| Incident detection | Automatic fork storm / runaway process detection | Manual rules & dashboards | ML-driven (premium tiers) | Manual thresholds |
| Data ownership | Runs entirely on your hosts (BYO LLM endpoint) | Self-hosted metrics backend | SaaS ingestion (vendor cloud) | Self-hosted or Elastic Cloud |
| Cost for 10 nodes | $0 (open source) | ~$50/mo infra costs | ~$1,500/mo | ~$1,000/mo |
| Ideal use case | Linux workload triage & AI explanations | Service-level metrics & alerting | Full-stack SaaS monitoring | Distributed tracing & logs |

## How to Use Them Together

- **Linnix + Prometheus**: Use Linnix for process-level ground truth and AI remediation hints, while Prometheus/Grafana remain the long-term metrics store. Linnix already exposes `/metrics/prometheus` so you can scrape fork/exec counts or rule activity into Prometheus without extra agents.
- **Linnix + Datadog/Elastic**: Keep your existing SaaS monitoring for fleet-wide SLIs or tracing, but deploy Linnix on the noisy hosts to explain *why* a spike happened (“cron fork storm”, “container image thrashing page cache”) and ship the summary into your incident tickets.
- **Migration path**: Teams frequently start with Datadog or Elastic for everything, then add Linnix to shrink SaaS footprint (edge nodes, air-gapped clusters) or to gain privacy-respecting AI analytics with <1% overhead.

## Key Differentiators

1. **Kernel-native coverage** – sched tracepoints capture every process even if it dies before a userspace agent samples it. Exporter-based systems simply miss these bursty events.
2. **LLM reasoning loop** – cognitod feeds structured events into the Linnix reasoner (BYO OpenAI, llama.cpp, or the bundled `linnix-3b` quantized model) to generate human-readable incident digests in seconds.
3. **Data stays on your metal** – there is no SaaS ingestion requirement. Run the daemon, dashboard, and LLM endpoint locally for compliance-sensitive environments.
4. **Zero-touch instrumentation** – no code changes, no sidecars. eBPF hooks + BTF offset resolution keep the binary compatible across kernels (5.8+ recommended).

**Bottom line**: Keep Prometheus (metrics) or your favorite APM (traces/logs). Add Linnix when you need kernel-level visibility and AI guidance without paying per-host SaaS tax.
