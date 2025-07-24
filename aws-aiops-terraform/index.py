import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    try:
        metric = float(event.get("metric", 0.5))  # Valor por defecto: 0.5
        logger.info(f"Received metric: {metric}") #para que se vea en los logs de cloudwatch

        if metric > 0.8:
            logger.warning("⚠️ High value detected! Possible anomaly.")
            return {
                "statusCode": 200,
                "body": json.dumps({"alert": True, "value": metric})
            }
        else:
            logger.info("✅ Normal value") #para que se vea en los logs de cloudwatch
            return {
                "statusCode": 200,
                "body": json.dumps({"alert": False, "value": metric})
            }

    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
