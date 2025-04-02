# Helm Chart


## Images

Images is on dockerhub

## Deploy chart

First you should write your own configuration file named `myvalues.yaml` (see [values.yaml](./values.yaml))
Review keys containing `password` in name
Select the desired version by setting the image tag eg : `4.1.15`, default is `latest`.

Set the image tag on specific tag is strongly recommended for avoid uncontroled stack upgrade.

You can check keys containing `enabled` for enabled or disabled service and using yours like `mysql` or `elasticsearch`.  

Files named `*_values.yaml` are Git ignored

### install

```bash
helm install phraseanet "infra/helm/all" -f "infra/helm/myvalues.yaml" --namespace phraseanet
```

### upgrade

```bash
helm upgrade -f "my_values.yaml" -n phraseanet  phraseanet ./ 
```

### uninstall

```bash
helm uninstall phraseanet --namespace phraseanet 
```
