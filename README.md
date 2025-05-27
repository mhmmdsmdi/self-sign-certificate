# SSL Certificate Generation Script

An automated bash script for generating SSL certificates with custom Certificate Authority (CA) for development and testing purposes.

## Features

- **Interactive Certificate Generation**: Prompts for certificate names, passwords, and network configuration
- **Dynamic IP/Domain Support**: Automatically detects system IPs and allows custom domains
- **Flexible CA Management**: Creates new CA or reuses existing one
- **Multiple Output Formats**: Generates encrypted/unencrypted keys, certificates, and PKCS#12 bundles
- **Customizable Organization Details**: Easy configuration through variables

## Prerequisites

- OpenSSL installed on your system
- Bash shell environment
- Write permissions in the script directory

## Configuration

Before running the script, **you must modify** the certificate configuration variables at the beginning of the script according to your organization:

```bash
# Certificate Configuration Variables
COMPANY_NAME="Your Company Name"
ORGANIZATION_NAME="Your Organization Inc"
ORGANIZATIONAL_UNIT="Your Department"
COUNTRY_CODE="US"
STATE_PROVINCE="Your State"
LOCALITY="Your City"
EMAIL_ADDRESS="admin@yourcompany.com"
COMMON_NAME="Your Company Name"
DEFAULT_PASSWORD="YourSecurePassword123!"
```

#### Example : Technology Company

```bash
COMPANY_NAME="TechNova Solutions"
ORGANIZATION_NAME="TechNova Solutions Inc"
ORGANIZATIONAL_UNIT="Engineering"
COUNTRY_CODE="US"
STATE_PROVINCE="California"
LOCALITY="San Francisco"
EMAIL_ADDRESS="admin@technova.com"
COMMON_NAME="TechNova Solutions"
DEFAULT_PASSWORD="TechNova2024!"
```

## Usage

### 1. Make the script executable

```bash
chmod +x generate-certificate.sh
```

### 2. Run the script

```bash
./generate-certificate.sh
```

### 3. Follow the interactive prompts

The script will guide you through:

1. **Certificate Name**: Enter a name for your certificate (used for files and directories)
2. **Passwords**: Set passwords for CA key, server key, and PFX bundle
3. **IP Addresses**: Add custom IP addresses (script auto-detects system IPs)
4. **Domain Names**: Add domain names for the certificate
5. **Confirmation**: Review settings before generation

## Output Files

The script creates the following directory structure:

```
├── ca/
│   ├── cakey.pem          # CA private key (encrypted)
│   ├── cacert.pem         # CA certificate
│   ├── cacert.csr         # CA certificate signing request
│   └── ...                # Additional CA files
├── certificates/
│   └── [certificate-name]/
│       ├── [name].key         # Server private key (encrypted)
│       ├── [name]_no_pass.key # Server private key (unencrypted)
│       ├── [name].crt         # Server certificate
│       ├── [name].csr         # Server certificate signing request
│       └── [name].pfx         # PKCS#12 bundle
└── openssl_dynamic.cnf    # Generated OpenSSL configuration
```

## Advanced Usage

### Force New CA Creation

```bash
FORCE_NEW_CA=true ./generate-certificate.sh
```

### Batch Mode (Non-Interactive)

You can modify the script to run in batch mode by pre-setting variables or removing interactive prompts.

## Security Considerations

⚠️ **Important Security Notes:**

1. **Change Default Passwords**: Always modify the `DEFAULT_PASSWORD` variable before production use
2. **Secure Private Keys**: Keep your private keys secure and backed up
3. **Development Only**: These certificates are for development/testing purposes
4. **Certificate Validation**: For production, use certificates from trusted Certificate Authorities

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure the script has execute permissions (`chmod +x generate-certificate.sh`)
2. **OpenSSL Not Found**: Install OpenSSL on your system
3. **Directory Already Exists**: The script will reuse existing CA if found

### Error Messages

- `Certificate name cannot be empty!`: Provide a valid certificate name
- `Invalid IP format`: Enter valid IPv4 or IPv6 addresses
- `Invalid domain format`: Use valid domain name format

## File Formats Explained

- **`.pem`**: Privacy Enhanced Mail format (Base64 encoded)
- **`.crt`**: Certificate file
- **`.key`**: Private key file
- **`.csr`**: Certificate Signing Request
- **`.pfx`**: PKCS#12 bundle (contains certificate and private key)

## Use Cases

- **Local Development**: HTTPS development servers
- **Internal Testing**: Staging environments
- **Microservices**: Container-to-container communication
- **API Testing**: Secure API endpoints
- **Load Balancer Testing**: SSL termination testing

## Contributing

Feel free to submit issues, feature requests, or improvements to this script.