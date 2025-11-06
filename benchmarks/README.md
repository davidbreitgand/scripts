## Bennchmarks of openai-go ChatCompletionNewParams parsing

To execute the benchmark with predefined iterations and sizes, run:
```bash
go run openai-parse-bench.go \
  --iterations=30 \
  --sizes=1,148,256,512,1024 \
  --output=benchmark-results.csv
```

To run visualization:
```bash
./show
```

