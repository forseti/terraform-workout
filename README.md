#### Terraform Workout ####
This branch hosts project from [Terraform: Up and Running 2nd edition](https://learning.oreilly.com/library/view/terraform-up/9781492046899/)

##### Provider #####
```hcl
provider <PROVIDER> {
	[<CONFIG>...]
}
```

For example:
```hcl
provider aws {
	region = "us-east-2"
}
```

##### Resource #####
```hcl
resource <PROVIDER>_<TYPE> <NAME> {
	[<CONFIG>...]
}
```

##### Resource Attribute Reference #####

```hcl
<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>
```