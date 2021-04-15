#! /bin/bash

# $1 - apic URL
# $2 - tenant
# $3 - applicatiopn policy
# $4 - epg
# $5 - contract

#method: POST
#url: https://192.168.130.10/api/node/mo/uni/tn-Den_ze_zivota_aplikace_reloaded/ap-Hyperflex_event/epg-K8s-EPG/rsconsIf-k8s-deploy.json
#payload{"fvRsConsIf":{"attributes":{"dn":"uni/tn-Den_ze_zivota_aplikace_reloaded/ap-Hyperflex_event/epg-K8s-EPG/rsconsIf-k8s-deploy","status":"deleted"},"children":[]}}


#method: POST
#url: https://192.168.130.10/api/node/mo/uni/tn-Den_ze_zivota_aplikace_reloaded/cif-k8s-deploy.json
#payload{"vzCPIf":{"attributes":{"dn":"uni/tn-Den_ze_zivota_aplikace_reloaded/cif-k8s-deploy","status":"deleted"},"children":[]}}

curl -s -k -d "<aaaUser name=admin pwd=Passw0rd./>" -c COOKIE.file -X POST $1/api/mo/aaaLogin.xml

curl -k -b COOKIE.file -X POST $1/api/node/mo/uni/tn-$2/ap-$3/epg-$4/rsconsIf-$5.json \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "fvRsConsIf": {
    "attributes": {
      "dn":"uni/tn-$2/ap-$3/epg-$4/rsconsIf-$5",
      "status":"deleted"
    },
    "children":[]
  }
}
EOF

curl -k -b COOKIE.file -X POST $1/api/node/mo/uni/tn-$2/cif-$5.json \
-H 'Content-Type: application/json; charset=utf-8' \
--data-binary @- << EOF
{
  "vzCPIf":{
    "attributes":{
      "dn":"uni/tn-$2/cif-$5",
      "status":"deleted"
    },
    "children":[]
  }
}
EOF