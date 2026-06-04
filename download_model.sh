#!/bin/bash
MODEL_DIR="/home/jorgeabm/.local/share/powermax_1rm/flutter_gemma"
MODEL_PATH="$MODEL_DIR/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm"

mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_PATH" ]; then
    echo "✅ El modelo Qwen2.5 1.5B ya está descargado en: $MODEL_PATH"
else
    echo "📥 Descargando Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm (aprox. 1.6 GB)..."
    echo "Esto puede tardar unos minutos dependiendo de tu conexión a internet."
    wget -O "$MODEL_PATH" "https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm"
    if [ $? -eq 0 ]; then
        echo "✅ Descarga completada con éxito en: $MODEL_PATH"
    else
        echo "❌ Error al descargar el modelo. Verifica tu conexión a internet e inténtalo de nuevo."
        exit 1
    fi
fi
