import os
import socket
import boto3

def lambda_handler(event, context):
    # IP and port to check
    ip_address = event['IP_ADDR']
    port = int(event['PORT'])
    zone_name = event['NAME']
    status = "FAIL"

    # Create a socket to check the connection
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)  # Set the socket timeout (adjust as needed)

    try:
        # Attempt to connect to the IP and port
        result = sock.connect_ex((ip_address, port))

        if result == 0:
            print(f"Connection to {ip_address}:{port} is successful")
            status = "OK"
        else:
            print(f"Connection to {ip_address}:{port} failed")
            status = "FAIL"

        # Send the result to CloudWatch alarm
        cloudwatch = boto3.client('cloudwatch', region_name = 'us-east-1')
        cloudwatch.put_metric_data(
            Namespace='IPPortHealth',
            MetricData=[
                {
                    'MetricName': 'HealthStatus',
                    'Dimensions': [
                        {
                            'Name': 'IP',
                            'Value': ip_address
                        },
                        {
                            'Name': 'Port',
                            'Value': str(port)
                        },
                        {
                            'Name': 'Name',
                            'Value': zone_name
                        },
                    ],
                    'Value': 1 if status == "OK" else 0,
                    'Unit': 'Count'
                }
            ]
        )

    except Exception as e:
        print(f"An error occurred: {str(e)}")
        # Handle the error as needed

    finally:
        sock.close()
