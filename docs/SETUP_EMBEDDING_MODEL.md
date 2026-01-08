# Setting Up the Embedding Model

## Download Universal Sentence Encoder Lite

### Option 1: Download Pre-converted TFLite Model

1. **Download the model**:
   ```bash
   # Create assets/models directory
   mkdir -p assets/models

   # Download USE-Lite TFLite model (you'll need to find a hosted version)
   # Alternatively, convert from TensorFlow Hub yourself
   ```

### Option 2: Convert from TensorFlow Hub (Recommended)

1. **Install TensorFlow** (on your development machine):
   ```bash
   pip install tensorflow tensorflow-hub
   ```

2. **Convert to TFLite**:
   ```python
   import tensorflow as tf
   import tensorflow_hub as hub

   # Load USE model
   embed = hub.load("https://tfhub.dev/google/universal-sentence-encoder-lite/2")

   # Convert to TFLite
   converter = tf.lite.TFLiteConverter.from_saved_model("path/to/saved/model")
   converter.optimizations = [tf.lite.Optimize.DEFAULT]
   tflite_model = converter.convert()

   # Save
   with open('assets/models/use_lite.tflite', 'wb') as f:
       f.write(tflite_model)
   ```

### Option 3: Use Pre-bundled Model (Easiest)

For now, I'll provide instructions to download a compatible model:

1. Visit: https://tfhub.dev/google/lite-model/universal-sentence-encoder-qa-ondevice/1
2. Download the TFLite model
3. Place it in `assets/models/use_lite.tflite`

## Update pubspec.yaml

Add the model to assets:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/models/use_lite.tflite  # Add this line
```

## Model Specifications

- **Model**: Universal Sentence Encoder Lite
- **Input**: String (text)
- **Output**: 512-dimensional embedding vector
- **Size**: ~1-2 MB
- **Performance**: ~10-50ms per encoding on mobile

## Next Steps

After placing the model file:

1. Run `flutter pub get` to install tflite_flutter
2. Update `pubspec.yaml` to include the model in assets
3. Test the EmbeddingService initialization
4. Proceed with vector search implementation
