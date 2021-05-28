#!/usr/bin/env bash

if [[ -z "$ARM_SUBSCRIPTION_ID" || -z "$ARM_RESOURCE_GROUP" ]]; then
    echo "Required env variables not defined"
    echo "Run the following and try again:"
    echo "    - export ARM_SUBSCRIPTION_ID=<your_subscription_id>"
    echo "    - export ARM_RESOURCE_GROUP=<your_resource_group_name>"
fi

terraform import azurerm_resource_group.rg \
    "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${ARM_RESOURCE_GROUP}"
