FROM ollama/ollama:latest

# Install wget if not present
RUN apt-get update && apt-get install -y wget curl && rm -rf /var/lib/apt/lists/*

# Download Heretic GGUF (Q4_K_M - 16.6 GB, good quality/size balance)
RUN wget -q https://huggingface.co/mradermacher/Qwen3.5-27B-heretic-GGUF/resolve/main/Qwen3.5-27B-heretic.Q4_K_M.gguf -O /root/Qwen3.5-27B-heretic.Q4_K_M.gguf

# Create modelfile
RUN echo -e 'FROM /root/Qwen3.5-27B-heretic.Q4_K_M.gguf\nRENDERER qwen3-coder\nPARSER qwen3-coder\nPARAMETER num_ctx 65536\nPARAMETER num_predict -1\nPARAMETER temperature 1\nPARAMETER top_p 0.95\nPARAMETER top_k 20\nPARAMETER presence_penalty 1.5' > /tmp/Modelfile.heretic

# Build the model into Ollama's model store - wait for server to be ready
RUN ollama serve & \
    PID=$! && \
    sleep 5 && \
    for i in $(seq 1 30); do \
        if curl -sf http://localhost:11434 > /dev/null 2>&1; then \
            echo "Ollama server ready!"; \
            break; \
        fi; \
        sleep 2; \
    done && \
    ollama create gppa-heretic -f /tmp/Modelfile.heretic && \
    kill $PID

EXPOSE 11434
CMD ["serve"]
