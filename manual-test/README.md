# Manual Module Test

Edit `terraform.tfvars` to try different module inputs.

```bash
cd manual-test
terraform init
terraform plan
```

Use `terraform apply` to display the outputs. This directory uses the module in its parent directory (`source = "./.."`).