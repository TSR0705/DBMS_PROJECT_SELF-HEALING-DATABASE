class MetricsAnalyzer:
    @staticmethod
    def calculate_improvement(before, after, metric_name):
        if before == 0: return 1.0 if after == 0 else 0.0
        improvement = (before - after) / before
        return round(improvement, 2)

    @staticmethod
    def analyze_latency(detected_at, executed_at):
        delta = (executed_at - detected_at).total_seconds()
        if delta > 3:
            return False, f"Latency Critical: {delta}s (Threshold: 3s)"
        return True, f"Latency OK: {delta}s"
