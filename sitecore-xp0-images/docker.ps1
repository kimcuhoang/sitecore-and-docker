
$ErrorActionPreference = "STOP"
$ProgressPreference = "SilentlyContinue"

& docker-compose -f .\docker-compose.yaml build -m 4g