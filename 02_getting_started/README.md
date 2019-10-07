### 02_getting_started ###
Set the environment variables:
```console
export AWS_ACCESS_KEY_ID=<YOUR_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<YOUR_SECRET_ACCESS_KEY>
```

#### Initialize a Terraform project ####
```console
terraform init
terraform init <DIR_OR_PLAN>
```

Example:
```console
terraform init v01_setup
```

#### Run the plan (preview) ####
```console
terraform plan
terraform plan <DIR_OR_PLAN>
```

Example:
```console
terraform plan v01_setup
```

#### Apply the changes ####
```console
terraform apply
terraform apply <DIR_OR_PLAN>
```

Example:
```console
terraform apply v01_setup
```

#### To display the graph (*DOT* format) ####
```console
terraform graph
terraform graph <DIR_OR_PLAN>
```

Example:
```console
terraform graph v03_deploy_web_server
```

An output's example:
```console
digraph {
        compound = "true"
        newrank = "true"
        subgraph "root" {
                "[root] aws_instance.example-instance" [label = "aws_instance.example-instance", shape = "box"]
                "[root] aws_security_group.example-sg" [label = "aws_security_group.example-sg", shape = "box"]
                "[root] provider.aws" [label = "provider.aws", shape = "diamond"]
                "[root] aws_instance.example-instance" -> "[root] aws_security_group.example-sg"
                "[root] aws_security_group.example-sg" -> "[root] provider.aws"
                "[root] meta.count-boundary (EachMode fixup)" -> "[root] aws_instance.example-instance"
                "[root] provider.aws (close)" -> "[root] aws_instance.example-instance"
                "[root] root" -> "[root] meta.count-boundary (EachMode fixup)"
                "[root] root" -> "[root] provider.aws (close)"
        }
}
```

The `digraph` value can be visualized in an online tool like [GraphvizOnline](http://dreampuf.github.io/GraphvizOnline/)

#### Input variables ####
To define a variable, use the following syntax:
```hcl
variable "<NAME>" {
	[<CONFIG> ...]
}
```

The body of the `variable` declaration (`<CONFIG`) has three parameters:

| Parameter | Description |
|---------- |-|
| *description*    | A description on how a variable is used |
| *type* | The *type constraints* of a variable |
| *default* | There are two ways to provide a value for a variable, `-var`, `-var-file`, and an environment variable `TF_FAR_<VARIABLE_NAME>`. If no value is passed in, the variable will fall back to this default value | 

An example of a number:
```hcl
variable "number_example" {
	description = "An example of a number"
	type = number
	default = 123
}

```

An example of a list:
```hcl
variable "list_example" {
	description = "An example of a list"
	type = list
	default = ['one', 'two', 'three']
}
```

An example of a list of numerics:
```hcl
variable "list_numeric_example" {
	description = "An example of a list of numerics"
	type = list(number)
	default = [1, 2, 3]
}
```

An example of a map:
```hcl
variable "map_example" {
	description = "An example of a map"
	type = map(string)
	default = {
		key1 = "value1"
		key2 = "value2"
		key3 = "value3"
	}
}
```

An example of an object:
```hcl
variable "object_example" {
	description = "An example of an object"
	type = object({
		name = string
		age = number
		tags = list(string)
		enabled = bool
	})
	default = {
		name = "object_1"
		age = 1
		tags = ["o", "n", "e"]
		enabled = true
	}
}
```

##### Input variable prompt #####
If there is no `default` value, running a command like `terraform apply` or `terraform plan` will prompt you to enter a value.

##### Using `-var` #####
One way to provide a value is to use `-var`:
```console
terraform plan -var "<VARIABLE_NAME>=<VALUE>"
terraform plan <DIR_OR_PLAN> -var "<VARIABLE_NAME>=<VALUE>"
```

Example:
```
terraform plan 05_deploy_configurable_web_server -var "server_port=8080"
```

##### Using environment variables (TF_VAR_) #####
And another way to provide a value is to use an environment variable `TF_VAR_<VARIABLE_NAME>`:
```console
export TF_VAR_<VARIABLE_NAME>=<VALUE>
terraform plan
```

```console
export TF_VAR_<VARIABLE_NAME>=<VALUE>
terraform plan <DIR_OR_PLAN>
```

Example:
```console
export TF_VAR_server_port=8080
terraform plan 05_deploy_configurable_web_server
```

#### Output variables ####
We can also define an `output` variable:
```hcl
output "<NAME>" {
	value = <VALUE>
	[<CONFIG> ...]
}
```

The body of the `output` declaration (`<CONFIG`) has two parameters:

| Parameter | Description |
|---------- |-|
| *description*    | A description of the type of the output |
| *sensitive* | If this parameter is set to true, Terraform will not log this output |

After `terraform apply`, we can use the following command to display the `output`
```console
terraform output
terraform output <OUTPUT_NAME>
```

```console
terraform output public_ip
```