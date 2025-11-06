package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/buger/jsonparser"
	"github.com/openai/openai-go/v3"
	"github.com/tidwall/gjson"
)

type BenchmarkResult struct {
	PayloadSize  string
	Method       string
	Iterations   int
	TotalTime    float64
	AvgTime      float64
	AllocsPerRun float64
	HeapKB       uint64
}

func generatePayload(sizeKB int) []byte {
	base := `{"messages":[`
	message := `{"role":"user","content":[{"text":"` + strings.Repeat("x", 80) + `"}]},`
	numMessages := (sizeKB * 1024) / len(message)
	payload := base + strings.Repeat(message, numMessages)
	payload = strings.TrimSuffix(payload, ",") + `],"model":"gpt-4o-mini"}`
	return []byte(payload)
}

func measureBenchmark(name string, iterations int, fn func() error) BenchmarkResult {
	runtime.GC()
	allocs := testing.AllocsPerRun(iterations, func() {
		_ = fn()
	})

	start := time.Now()
	for i := 0; i < iterations; i++ {
		if err := fn(); err != nil {
			fmt.Printf("%s failed: %v\n", name, err)
			break
		}
	}
	duration := time.Since(start)

	runtime.GC()
	var mem runtime.MemStats
	runtime.ReadMemStats(&mem)

	return BenchmarkResult{
		Method:       name,
		Iterations:   iterations,
		TotalTime:    float64(duration.Milliseconds()),
		AvgTime:      float64(duration.Milliseconds()) / float64(iterations),
		AllocsPerRun: allocs,
		HeapKB:       mem.HeapAlloc / 1024,
	}
}

func benchmarkUnmarshal(data []byte, iterations int) BenchmarkResult {
	return measureBenchmark("Full", iterations, func() error {
		var params openai.ChatCompletionNewParams
		return params.UnmarshalJSON(data)
	})
}

func benchmarkSelectiveUnmarshal(data []byte, iterations int) BenchmarkResult {
	return measureBenchmark("Selective", iterations, func() error {
		var rb struct {
			Model string `json:"model"`
		}
		return json.Unmarshal(data, &rb)
	})
}

func benchmarkPartialUnmarshal(data []byte, iterations int) BenchmarkResult {
	return measureBenchmark("Partial", iterations, func() error {
		var m map[string]json.RawMessage
		if err := json.Unmarshal(data, &m); err != nil {
			return err
		}
		var model string
		return json.Unmarshal(m["model"], &model)
	})
}

func benchmarkJsonParser(data []byte, iterations int) BenchmarkResult {
	return measureBenchmark("JsonParser", iterations, func() error {
		_, _, _, err := jsonparser.Get(data, "model")
		return err
	})
}

func benchmarkGJSON(data []byte, iterations int) BenchmarkResult {
	return measureBenchmark("GJSON", iterations, func() error {
		_ = gjson.GetBytes(data, "model")
		return nil
	})
}

func main() {
	iterations := flag.Int("iterations", 30, "Number of iterations per benchmark")
	sizesFlag := flag.String("sizes", "1,25,200,1024", "Comma-separated payload sizes in KB")
	output := flag.String("output", "benchmark_results.csv", "CSV output file")
	flag.Parse()

	sizeStrings := strings.Split(*sizesFlag, ",")
	var results []BenchmarkResult

	for _, s := range sizeStrings {
		var sizeKB int
		fmt.Sscanf(s, "%d", &sizeKB)
		payload := generatePayload(sizeKB)
		sizeLabel := fmt.Sprintf("%dKB", sizeKB)

		r1 := benchmarkUnmarshal(payload, *iterations)
		r1.PayloadSize = sizeLabel
		results = append(results, r1)

		r2 := benchmarkSelectiveUnmarshal(payload, *iterations)
		r2.PayloadSize = sizeLabel
		results = append(results, r2)

		r3 := benchmarkPartialUnmarshal(payload, *iterations)
		r3.PayloadSize = sizeLabel
		results = append(results, r3)

		r4 := benchmarkJsonParser(payload, *iterations)
		r4.PayloadSize = sizeLabel
		results = append(results, r4)

		r5 := benchmarkGJSON(payload, *iterations)
		r5.PayloadSize = sizeLabel
		results = append(results, r5)
	}

	file, err := os.Create(*output)
	if err != nil {
		fmt.Printf("Failed to create CSV file: %v\n", err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	writer.Write([]string{"PayloadSize", "Method", "Iterations", "TotalTime(ms)", "AvgTime(ms)", "AllocsPerRun", "HeapKB"})
	for _, r := range results {
		writer.Write([]string{
			r.PayloadSize,
			r.Method,
			fmt.Sprintf("%d", r.Iterations),
			fmt.Sprintf("%.2f", r.TotalTime),
			fmt.Sprintf("%.2f", r.AvgTime),
			fmt.Sprintf("%.2f", r.AllocsPerRun),
			fmt.Sprintf("%d", r.HeapKB),
		})
	}

	fmt.Printf("Benchmark results written to %s\n", *output)
}
