import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Read CSV
csv_file = "./benchmark-results.csv"  # Update this path
df = pd.read_csv(csv_file)

# Ensure correct data types
df['AvgTime(ms)'] = df['AvgTime(ms)'].astype(float)
df['AllocsPerRun'] = df['AllocsPerRun'].astype(float)
df['HeapKB'] = df['HeapKB'].astype(float)

# Set style
sns.set(style="whitegrid")

# Create a single figure with 3 subplots
fig, axes = plt.subplots(1, 3, figsize=(18, 6))

# --- Subplot 1: AvgTime ---
sns.barplot(data=df, x="PayloadSize", y="AvgTime(ms)", hue="Method", ax=axes[0])
axes[0].set_title("Average Time per Method")
axes[0].set_ylabel("Avg Time (ms)")
axes[0].set_xlabel("Payload Size")
axes[0].set_yscale('log')
axes[0].legend(title="Method")

# --- Subplot 2: Allocations ---
sns.barplot(data=df, x="PayloadSize", y="AllocsPerRun", hue="Method", ax=axes[1])
axes[1].set_title("Allocations per Method")
axes[1].set_ylabel("Allocations per Run")
axes[1].set_xlabel("Payload Size")
axes[1].set_yscale('log')
axes[1].legend(title="Method")

# --- Subplot 3: Heap Usage ---
sns.barplot(data=df, x="PayloadSize", y="HeapKB", hue="Method", ax=axes[2])
axes[2].set_title("Heap Usage per Method")
axes[2].set_ylabel("Heap (KB)")
axes[2].set_xlabel("Payload Size")
axes[2].set_yscale('log')
axes[2].legend(title="Method")

plt.tight_layout()
#plt.show()
plt.savefig("benchmark_summary.png")
print("✅ Combined visualization saved as benchmark_summary.png")
