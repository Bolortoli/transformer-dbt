from flask import Flask, request, jsonify
import subprocess
import os
import logging
import threading
from datetime import datetime

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

# Global variable to track last execution
last_execution = {"time": None, "status": None, "message": None}

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({
        "status": "healthy",
        "service": "dbt-transformer",
        "timestamp": datetime.now().isoformat(),
        "last_execution": last_execution
    })

@app.route('/run', methods=['POST', 'GET'])
def run_dbt():
    def execute_dbt():
        global last_execution
        try:
            logging.info("Starting dbt deployment...")
            last_execution["time"] = datetime.now().isoformat()
            last_execution["status"] = "running"
            
            # Set environment variables
            env = os.environ.copy()
            env['DBT_TARGET'] = 'prod'
            env['BIGQUERY_DATASET'] = 'transformer_dbt_prod'
            
            # Run dbt deployment
            result = subprocess.run(
                ['./deploy.sh', 'prod', 'run'], 
                capture_output=True, 
                text=True,
                env=env,
                timeout=1200  # 20 minutes timeout
            )
            
            if result.returncode == 0:
                logging.info("dbt deployment completed successfully")
                last_execution["status"] = "success"
                last_execution["message"] = "Deployment completed successfully"
            else:
                logging.error(f"dbt deployment failed: {result.stderr}")
                last_execution["status"] = "error"
                last_execution["message"] = f"Deployment failed: {result.stderr[-500:]}"
                
        except Exception as e:
            logging.error(f"Error running dbt: {str(e)}")
            last_execution["status"] = "error"
            last_execution["message"] = f"Error: {str(e)}"
    
    # Run in background thread to avoid timeout
    thread = threading.Thread(target=execute_dbt)
    thread.start()
    
    return jsonify({
        "status": "started",
        "message": "dbt deployment started in background",
        "timestamp": datetime.now().isoformat()
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
