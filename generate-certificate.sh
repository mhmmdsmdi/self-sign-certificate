#!/bin/bash
set -e  # Exit on any error

# Certificate Configuration Variables
COMPANY_NAME="TechNova Solutions"
ORGANIZATION_NAME="TechNova Solutions Inc"
ORGANIZATIONAL_UNIT="Engineering"
COUNTRY_CODE="US"
STATE_PROVINCE="California"
LOCALITY="San Francisco"
EMAIL_ADDRESS="admin@technova.com"
COMMON_NAME="TechNova Solutions"
DEFAULT_PASSWORD="TechNova2024!"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get IP addresses and domains
get_ip_domains() {
    echo
    print_status "Collecting IP addresses and domains for certificate..."
    
    # Arrays to store IPs and domains
    declare -a IP_ADDRESSES
    declare -a DOMAINS
    
    # Add default entries
    IP_ADDRESSES+=("127.0.0.1")
    IP_ADDRESSES+=("::1")
    DOMAINS+=("localhost")
    DOMAINS+=("*.localhost")
    
    # Get current system IP addresses
    print_status "Detecting system IP addresses..."
    declare -a FOUND_IPS
    while IFS= read -r ip; do
        if [[ -n "$ip" && "$ip" != "127.0.0.1" ]]; then
            FOUND_IPS+=("$ip")
            print_status "Found system IP: $ip"
        fi
    done < <(hostname -I 2>/dev/null | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
    
    # Interactive input for additional IPs
    echo
    print_status "Enter additional IP addresses (press Enter to skip, 'done' to finish):"
    while true; do
        read -p "IP Address: " additional_ip
        if [[ -z "$additional_ip" || "$additional_ip" == "done" ]]; then
            break
        fi
        
        # Basic IP validation
        if [[ "$additional_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            IP_ADDRESSES+=("$additional_ip")
            print_success "Added IP: $additional_ip"
        elif [[ "$additional_ip" =~ ^[0-9a-fA-F:]+$ ]]; then
            IP_ADDRESSES+=("$additional_ip")
            print_success "Added IPv6: $additional_ip"
        else
            print_error "Invalid IP format: $additional_ip"
        fi
    done
    
    # Interactive input for domains
    echo
    print_status "Enter domain names (press Enter to skip, 'done' to finish):"
    while true; do
        read -p "Domain: " additional_domain
        if [[ -z "$additional_domain" || "$additional_domain" == "done" ]]; then
            break
        fi
        
        # Basic domain validation
        if [[ "$additional_domain" =~ ^[a-zA-Z0-9*.-]+$ ]]; then
            DOMAINS+=("$additional_domain")
            print_success "Added domain: $additional_domain"
        else
            print_error "Invalid domain format: $additional_domain"
        fi
    done
    
    # Display collected entries
    echo
    print_status "Certificate will include the following entries:"
    echo "IP Addresses:"
    for i in "${!IP_ADDRESSES[@]}"; do
        echo "  IP.$((i+1)) = ${IP_ADDRESSES[$i]}"
    done
    echo "Domains:"
    for i in "${!DOMAINS[@]}"; do
        echo "  DNS.$((i+1)) = ${DOMAINS[$i]}"
    done
    
    # Generate alt_names section for OpenSSL config
    ALT_NAMES_CONFIG=""
    for i in "${!DOMAINS[@]}"; do
        ALT_NAMES_CONFIG+="DNS.$((i+1)) = ${DOMAINS[$i]}\n"
    done
    for i in "${!IP_ADDRESSES[@]}"; do
        ALT_NAMES_CONFIG+="IP.$((i+1)) = ${IP_ADDRESSES[$i]}\n"
    done
    
    echo
    read -p "Proceed with these settings? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_error "Certificate generation cancelled by user."
        exit 1
    fi
}

# Function to create dynamic OpenSSL configuration
create_openssl_config() {
    print_status "Creating dynamic OpenSSL configuration..."
    
    cat > openssl_dynamic.cnf << EOF
[ ca ]
default_ca     = CA_default

[ CA_default ]
dir            = ./ca
certs          = \$dir/certs
database       = \$dir/index.txt
new_certs_dir  = \$dir/newcerts
certificate    = \$dir/cacert.pem
serial         = \$dir/serial
crlnumber      = \$dir/crlnumber
crl            = \$dir/crl.pem
private_key    = \$dir/cakey.pem
RANDFILE       = \$dir/.rand
unique_subject = no
default_days   = 3650
default_crl_days= 30
default_md     = sha256
policy         = policy_anything 
countryName_default = ${COUNTRY_CODE}
stateOrProvinceName_default = ${STATE_PROVINCE}
localityName_default        = ${LOCALITY}
0.organizationName_default  = ${ORGANIZATION_NAME}
CipherString   = AES256-SHA

[ policy_anything ]
countryName             = match
stateOrProvinceName     = match
localityName            = match
organizationName        = match
organizationalUnitName  = optional
commonName              = match
emailAddress            = match

[ req ]
default_bits       = 2048
default_keyfile    = privkey.pem
distinguished_name = req_distinguished_name
attributes         = req_attributes
input_password     = ${DEFAULT_PASSWORD}
output_password    = ${DEFAULT_PASSWORD}

[ req_distinguished_name ]
countryName                    = Country Name
countryName_default            = ${COUNTRY_CODE}
countryName_min                = 2
countryName_max                = 2
stateOrProvinceName            = State or Province Name
stateOrProvinceName_default    = ${STATE_PROVINCE}
localityName                   = Locality Name
localityName_default           = ${LOCALITY}
0.organizationName             = Organization Name
0.organizationName_default     = ${ORGANIZATION_NAME}
organizationalUnitName         = Organizational Unit Name
organizationalUnitName_default = ${ORGANIZATIONAL_UNIT}
commonName                     = Common Name
commonName_default             = ${COMMON_NAME}
commonName_max                 = 64
emailAddress                   = Email Address
emailAddress_default           = ${EMAIL_ADDRESS}
emailAddress_max               = 64

[ req_attributes ]
challengePassword        = A challenge password
challengePassword_min    = 4
challengePassword_max    = 20

[ v3_req ]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[ v3_ca ]
basicConstraints = critical, CA:TRUE

[alt_names]
EOF

    # Add the alt_names section
    echo -e "$ALT_NAMES_CONFIG" >> openssl_dynamic.cnf

    print_success "Dynamic OpenSSL configuration created: openssl_dynamic.cnf"
}

# Get certificate name
echo
print_status "Certificate Configuration"
read -p "Enter certificate name (will be used for directory and file names): " CERT_NAME

# Validate certificate name
if [[ -z "$CERT_NAME" ]]; then
    print_error "Certificate name cannot be empty!"
    exit 1
fi

# Sanitize certificate name (remove special characters, replace spaces with underscores)
CERT_NAME=$(echo "$CERT_NAME" | sed 's/[^a-zA-Z0-9_-]/_/g' | sed 's/__*/_/g')
print_success "Using certificate name: $CERT_NAME"

# Prompt for passwords interactively
echo
read -s -p "Enter CA Key Password: " CA_PASSPHRASE
echo
read -s -p "Enter Server Key Password: " SERVER_PASSPHRASE
echo
read -s -p "Enter PFX Password: " PFX_PASSPHRASE
echo

# Header
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}         Automated SSL Certificate Generation Script            ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo

print_warning "Running in fully automated mode"

# Get IP addresses and domains dynamically
get_ip_domains

# Create dynamic OpenSSL configuration
create_openssl_config

print_status "Using dynamic configuration from openssl_dynamic.cnf"
echo

# Step 1: Setup directories and files
print_status "Setting up directory structure and required files..."
mkdir -p ca ca/newcerts ca/certs "certificates/${CERT_NAME}"

# Set certificate directory
CERT_DIR="certificates/${CERT_NAME}"
print_success "Certificate directory created: $CERT_DIR"

# Check if CA already exists
if [[ -f "ca/cakey.pem" && -f "ca/cacert.pem" ]]; then
    print_warning "Existing Certificate Authority found!"
    print_status "Found: ca/cakey.pem and ca/cacert.pem"
    
    if [[ "${FORCE_NEW_CA}" == "true" ]]; then
        print_warning "FORCE_NEW_CA is set - creating new CA (existing files will be overwritten)"
        USE_EXISTING_CA=false
    else
        print_success "Using existing Certificate Authority (set FORCE_NEW_CA=true to override)"
        USE_EXISTING_CA=true
    fi
else
    print_status "No existing CA found. Creating new Certificate Authority..."
    USE_EXISTING_CA=false
fi

# Setup required files
if [[ ! -f "ca/index.txt" ]]; then
    touch ca/index.txt
fi
if [[ ! -f "ca/serial" ]]; then
    echo 1000 > ca/serial
fi
if [[ ! -f "ca/crlnumber" ]]; then
    echo 01 > ca/crlnumber
fi

print_success "Directory structure ready"

# Create CA only if needed
if [[ "$USE_EXISTING_CA" == false ]]; then
    # Step 2: Generate CA private key
    print_status "Generating Certificate Authority (CA) private key..."
    openssl genrsa -aes256 -out ./ca/cakey.pem -passout pass:${CA_PASSPHRASE} 4096
    print_success "CA private key generated successfully (4096-bit RSA with AES256 encryption)"
    print_status "Saved to: ./ca/cakey.pem"

    # Step 3: Create CA certificate signing request
    print_status "Creating Certificate Signing Request (CSR) for Certificate Authority..."
    openssl req -config openssl_dynamic.cnf -new -key ca/cakey.pem -out ca/cacert.csr -passin pass:${CA_PASSPHRASE} -batch
    print_success "CA certificate signing request created successfully"
    print_status "Saved to: ca/cacert.csr"

    # Step 4: Self-sign CA certificate
    print_status "Self-signing the Certificate Authority certificate..."
    print_status "Certificate will be valid for 10 years (3650 days)"
    openssl x509 -days 3650 -in ca/cacert.csr -req -signkey ca/cakey.pem -out ca/cacert.pem -passin pass:${CA_PASSPHRASE} -extensions v3_ca -extfile openssl_dynamic.cnf
    cp ca/cacert.pem ca/cacert.crt
    print_success "CA certificate signed and created successfully"
    print_status "Saved to: ca/cacert.pem"
else
    print_status "Skipping CA creation - using existing CA"
fi

# Step 5: Generate server private key
print_status "Generating server private key..."
openssl genrsa -aes256 -out "${CERT_DIR}/${CERT_NAME}.key" -passout pass:${SERVER_PASSPHRASE} 4096 
print_success "Server private key generated successfully (4096-bit RSA with AES256 encryption)"
print_status "Saved to: ${CERT_DIR}/${CERT_NAME}.key"

# Step 6: Create server certificate signing request
print_status "Creating Certificate Signing Request (CSR) for server certificate..."
openssl req -config openssl_dynamic.cnf -new -key "${CERT_DIR}/${CERT_NAME}.key" -out "${CERT_DIR}/${CERT_NAME}.csr" -passin pass:${SERVER_PASSPHRASE} -batch
print_success "Server certificate signing request created successfully"
print_status "Saved to: ${CERT_DIR}/${CERT_NAME}.csr"

# Step 7: Sign server certificate with CA
print_status "Signing server certificate with Certificate Authority..."
print_status "Using dynamically generated IP/domain extensions"
openssl ca -config openssl_dynamic.cnf -in "${CERT_DIR}/${CERT_NAME}.csr" -out "${CERT_DIR}/${CERT_NAME}.crt" -passin pass:${CA_PASSPHRASE} -extensions v3_req -batch
print_success "Server certificate signed successfully by CA"
print_status "Saved to: ${CERT_DIR}/${CERT_NAME}.crt"

# Step 8: Create PKCS#12 bundle
print_status "Creating PKCS#12 (.pfx) bundle for easy deployment..."
openssl pkcs12 -export -out "${CERT_DIR}/${CERT_NAME}.pfx" -inkey "${CERT_DIR}/${CERT_NAME}.key" -in "${CERT_DIR}/${CERT_NAME}.crt" -passin pass:${SERVER_PASSPHRASE} -passout pass:${PFX_PASSPHRASE}
print_success "PKCS#12 bundle created successfully"
print_status "Saved to: ${CERT_DIR}/${CERT_NAME}.pfx"

# Step 9: Create certificate without passphrase for easier deployment
print_status "Creating unencrypted server private key for easier deployment..."
openssl rsa -in "${CERT_DIR}/${CERT_NAME}.key" -out "${CERT_DIR}/${CERT_NAME}_no_pass.key" -passin pass:${SERVER_PASSPHRASE}
print_success "Unencrypted server private key created"
print_status "Saved to: ${CERT_DIR}/${CERT_NAME}_no_pass.key"

# Final summary
echo
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    CERTIFICATE GENERATION COMPLETE!           ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo
print_success "All certificates have been generated successfully!"
echo
print_status "Generated files:"
echo "  📁 Certificate Authority:"
echo "    • ca/cakey.pem         - CA private key (encrypted)"
echo "    • ca/cacert.pem        - CA certificate"
echo "    • ca/cacert.csr        - CA certificate request"
echo
echo "  📁 Server Certificate (${CERT_NAME}):"
echo "    • ${CERT_DIR}/${CERT_NAME}.key         - Server private key (encrypted)"
echo "    • ${CERT_DIR}/${CERT_NAME}_no_pass.key - Server private key (unencrypted)"
echo "    • ${CERT_DIR}/${CERT_NAME}.crt         - Server certificate"
echo "    • ${CERT_DIR}/${CERT_NAME}.csr         - Server certificate request" 
echo "    • ${CERT_DIR}/${CERT_NAME}.pfx         - PKCS#12 bundle"
echo
echo "  📁 Configuration Files:"
echo "    • openssl_dynamic.cnf  - Dynamic OpenSSL configuration"
echo
print_status "Passwords used:"
echo "  • CA Key Password:     ${CA_PASSPHRASE}"
echo "  • Server Key Password: ${SERVER_PASSPHRASE}"
echo "  • PFX Password:        ${PFX_PASSPHRASE}"
echo
print_warning "Remember to keep your private keys secure and backed up!"
print_warning "Change default passwords in production environments!"
print_status "Certificate generation process completed successfully."