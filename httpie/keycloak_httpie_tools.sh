__decode_base64_string() {
	local len=$((${#1} % 4))
  	local result="$1"
  	if [ $len -eq 2 ]; then result="$1"'=='
  	elif [ $len -eq 3 ]; then result="$1"'=' 
  	fi
  	echo "$result" | tr '_-' '/+' | base64 -d
}

kc_user_token() {
    username=$1
    password=$2
    config_file=$3

    client_id=$(cat $config_file | jq -r .client_id)
    client_secret=$(cat $config_file | jq -r .client_secret)
    host=$(cat $config_file | jq -r .host)
    realm=$(cat $config_file | jq -r .realm)

    http -b --form https://$host/auth/realms/$realm/protocol/openid-connect/token client_id=$client_id client_secret=$client_secret username=$username password=$password grant_type=password
}

kc_client_token() {
    config_file=$1

    client_id=$(cat $config_file | jq -r .client_id)
    client_secret=$(cat $config_file | jq -r .client_secret)
    host=$(cat $config_file | jq -r .host)
    realm=$(cat $config_file | jq -r .realm)

    http -b --form https://$host/auth/realms/$realm/protocol/openid-connect/token client_id=$client_id client_secret=$client_secret grant_type=client_credentials
}

__get_header_json() {
    token=$1
    body=$(echo $token | cut -d. -f1)
    __decode_base64_string $body
}

__get_payload_json() {
    token=$1
    body=$(echo $token | cut -d. -f2)
    __decode_base64_string $body
}

kc_show_token() {
    token=$1

    header=$(__get_header_json $token)
    body=$(__get_payload_json $token)

    echo "{\"header\":$header,\"payload\":$body}"
}

setup() {
    config_file_name=$1

    echo "Enter keycloak host"
    read keycloak_host
    echo "Enter realm name"
    read realm_name
    echo "Enter client_id"
    read client_id
    echo "Enter client_secret"
    read client_secret
    
    http -b https://$keycloak_host_name/auth/realms/$realm_name/.well-known/openid-configuration

    json_config="{\"client_id\":\"$client_id\",\"client_secret\":\"$client_secret\",\"host\":\"$keycloak_host\",\"realm\":\"$realm_name\"}"
    echo $json_config | tee $config_file_name
}

while [ "$1" != "" ]; do
    case $1 in
        setup_admin )           shift
                                export_config_file_name=$1
                                setup_admin $export_config_file_name
                                exit 1
                                ;;
        setup )                 shift
                                export_config_file_name=$1
                                setup $export_config_file_name
                                exit 1
                                ;;
        get_user_token )        shift
                                kc_user_token $1 $2 $3
                                exit 1
                                ;;
        get_client_token )      shift
                                kc_client_token $1
                                exit 1
                                ;;
        parse )                 shift
                                token=$1
                                kc_show_token $token
                                exit 1
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done