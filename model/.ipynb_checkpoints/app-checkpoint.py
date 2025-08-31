from flask import Flask, request, jsonify
import numpy as np
import librosa
import joblib
import os
from werkzeug.utils import secure_filename
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configuration
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'wav', 'mp3', 'flac', 'ogg', 'webm'}  # Added webm format
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max upload size

# Create upload folder if it doesn't exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Load the saved models
model = joblib.load('finalized_model.sav')
scaler = joblib.load('scaler.sav')
feature_selector = joblib.load('feature_selector.sav')
label_encoder = joblib.load('label_encoder.sav')

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def feature_extraction(file_path, sampling_rate=48000):
    """Extract audio features from the uploaded file"""
    features = []
    try:
        audio, _ = librosa.load(file_path, sr=sampling_rate)
        
        # Extract spectral features
        spectral_centroid = np.mean(librosa.feature.spectral_centroid(y=audio, sr=sampling_rate))
        spectral_bandwidth = np.mean(librosa.feature.spectral_bandwidth(y=audio, sr=sampling_rate))
        spectral_rolloff = np.mean(librosa.feature.spectral_rolloff(y=audio, sr=sampling_rate))
        
        features.append(spectral_centroid)
        features.append(spectral_bandwidth)
        features.append(spectral_rolloff)
        
        # Extract MFCCs
        mfcc = librosa.feature.mfcc(y=audio, sr=sampling_rate)
        for el in mfcc:
            features.append(np.mean(el))
            
        return features
    except Exception as e:
        print(f"Error extracting features: {e}")
        return None

@app.route('/')
def root():
    """Root endpoint that provides API information"""
    return jsonify({
        'name': 'Voice Age Prediction API',
        'version': '1.0',
        'endpoints': {
            '/predict_age': 'POST - Predict age from voice audio file',
            '/health': 'GET - Check API health status'
        }
    })

@app.route('/predict_age', methods=['POST'])
def predict_age():
    """API endpoint to predict age from voice"""
    try:
        # Check if the post request has the file part
        if 'file' not in request.files:
            return jsonify({'error': 'No file part'}), 400
        
        file = request.files['file']
        
        # If user does not select file, browser might send empty file without filename
        if file.filename == '':
            return jsonify({'error': 'No selected file'}), 400
        
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(file_path)
            
            try:
                # Extract features
                features = feature_extraction(file_path)
                
                if features is None:
                    return jsonify({'error': 'Error extracting features from audio file'}), 500
                
                # Preprocess features
                features_array = np.array(features).reshape(1, -1)
                scaled_features = scaler.transform(features_array)
                selected_features = feature_selector.transform(scaled_features)
                
                # Make prediction
                prediction = model.predict(selected_features)
                age_category = label_encoder.inverse_transform(prediction)[0]
                
                # Clean up the file after processing
                os.remove(file_path)
                
                return jsonify({
                    'predicted_age_category': age_category,
                    'success': True
                })
            except Exception as e:
                # Clean up file if there's an error
                if os.path.exists(file_path):
                    os.remove(file_path)
                print(f"Error processing audio: {e}")
                return jsonify({'error': f'Error processing audio: {str(e)}'}), 500
        
        return jsonify({'error': 'File type not allowed'}), 400
        
    except Exception as e:
        print(f"Error in predict_age: {e}")
        return jsonify({'error': f'Server error: {str(e)}'}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Simple endpoint to check if the API is running"""
    return jsonify({'status': 'ok', 'message': 'Age prediction API is running'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)