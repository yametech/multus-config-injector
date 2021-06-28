if [ ! $yce_dev_ip ]; then
  HOSTS='[
        "multus-cni-config-injector-service",
        "multus-cni-config-injector-service.kube-system",
        "multus-cni-config-injector-service.kube-system.svc",
        "multus-cni-config-injector-service.kube-system.svc:9443"
        ]'
else
  # shellcheck disable=SC2016
  HOSTS='['\"${yce_dev_ip}\"']'
fi

if [ ! $COUNTRY ]; then
COUNTRY=CN
fi
if [ ! $CITY ]; then
CITY=GuangZhou
fi

cat >  ca-config.json <<EOF
{
"signing": {
"default": {
  "expiry": "175200h"
},
"profiles": {
  "kubernetes-Soulmate": {
    "usages": [
        "signing",
        "key encipherment",
        "server auth",
        "client auth"
    ],
    "expiry": "175200h"
  }
}
}
}
EOF

cat >  ca-csr.json <<EOF
{
"CN": "kubernetes-Soulmate",
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
  "C": "${COUNTRY}",
  "ST": "${CITY}",
  "L": "${CITY}",
  "O": "k8s",
  "OU": "System"
}
]
}
EOF

cat > tls-csr.json <<EOF
{
  "CN": "yce",
	"hosts": $HOSTS,
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${COUNTRY}",
      "ST": "${CITY}",
      "L": "${CITY}",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes-Soulmate tls-csr.json | cfssljson -bare tls

openssl x509  -noout -text -in tls.pem
#openssl x509  -noout -text -in tls-key.pem
openssl x509  -noout -text -in ca.pem

mv tls-key.pem tls.key
mv tls.pem tls.crt

echo "tls.crt\r\n----------------------------------------------------------------"
cat tls.crt | base64
echo "----------------------------------------------------------------\r\n"
echo "tls.key\r\n----------------------------------------------------------------"
cat tls.key | base64
echo "----------------------------------------------------------------\r\n"
