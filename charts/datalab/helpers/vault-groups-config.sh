# To associate groups with the jwt provider use the API to:
# 1. Create a policy for the group
# 2. Create a group
# 3. Associate alias that matches group in token
# (pre-defined in the role cration) Use the groups_claim from the token in the role

# With VAULT_TOKEN and VAULT_ADDR in environment variables given when calling this script

# (pre-step, jwt acessor) 2.
JWT_ACESSOR=$(curl --header "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/sys/auth | jq -r '.["jwt/"].accessor')

# Given a list of existing group ids (written the same way as in Keycloak)
declare -a GROUP_LIST=("g1" "g2" "demo")

for GROUP in "${GROUP_LIST[@]}"
do

# 1. 
tee payload-pol.json <<EOF 
{
    "policy": "path \"onyxia-kv/projet-$GROUP/*\" {\n capabilities = [\"create\",\"update\",\"read\",\"delete\",\"list\"]\n}\n\n path \"onyxia-kv/data/projet-$GROUP/*\" {\n capabilities = [\"create\",\"update\",\"read\"]\n}\n\n path \"onyxia-kv/metadata/projet-$GROUP/*\" {\n capabilities = [\"delete\", \"list\", \"read\"]\n }"
}
EOF

curl --header "X-Vault-Token: $VAULT_TOKEN" \
   --request PUT \
   --data @payload-pol.json \
   $VAULT_ADDR/v1/sys/policies/acl/$GROUP

rm payload-pol.json


# 2.
tee payload-grp.json <<EOF
{
  "name": "$GROUP",
  "policies": ["$GROUP"],
  "type": "external",
  "metadata": {
    "origin": "onyxia"
  }
}
EOF

GROUP_ID=$(curl --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-grp.json \
    $VAULT_ADDR/v1/identity/group | jq -r ".data.id")

rm payload-grp.json


# 3.
tee payload-grp-alias.json <<EOF
{
  "canonical_id": "$GROUP_ID",
  "mount_accessor": "$JWT_ACESSOR",
  "name": "$GROUP"
}
EOF

curl --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload-grp-alias.json \
    $VAULT_ADDR/v1/identity/group-alias 

rm payload-grp-alias.json

done
