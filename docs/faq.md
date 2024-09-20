## Frequently Asked Questions

<details>
<summary><b>How do you change the models used in this sample?</b></summary><br>

You can use the environment variables to change the chat and embeddings models used in this sample when deployed.
Run these commands:

```bash
azd env set AZURE_OPENAI_API_MODEL gpt-4
azd env set AZURE_OPENAI_API_MODEL_VERSION  0125-preview
```

You may also need to adjust the capacity in `infra/main.bicep` file, depending on how much TPM your account is allowed.

</details>

<details>
<summary><b>What does the <code>azd up</code> command do?</b></summary><br>

The `azd up` command comes from the [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/overview), and takes care of both provisioning the Azure resources and deploying code to the selected Azure hosts.

The `azd up` command uses the `azure.yaml` file combined with the infrastructure-as-code `.bicep` files in the `infra/` folder. The `azure.yaml` file for this project declares several "hooks" for the prepackage step and postprovision steps. The `up` command first runs the `prepackage` hook which installs Node dependencies and builds the TypeScript files. It then packages all the code (both frontend and backend services) into a zip file which it will deploy later.

Next, it provisions the resources based on `main.bicep` and `main.parameters.json`. At that point, since there is no default value for the OpenAI resource location, it asks you to pick a location from a short list of available regions. Then it will send requests to Azure to provision all the required resources. With everything provisioned, it runs the `postprovision` hook to process the local data and add it to an Azure Cosmos DB index.

Finally, it looks at `azure.yaml` to determine the Azure host (Functions and Static Web Apps, in this case) and uploads the zip to Azure. The `azd up` command is now complete, but it may take some time for the app to be fully available and working after the initial deploy.

Related commands are `azd provision` for just provisioning (if infra files change) and `azd deploy` for just deploying updated app code.

</details>

<details>
<summary><b>I don't have access to Azure OpenAI, can I use the regular OpenAI API?</b></summary><br>

Yes! You can use the regular OpenAI API by setting the `OPENAI_API_KEY` environment variables. You can do this by running the following commands:

```bash
azd env set OPENAI_API_KEY <your-openai-api-key>
```

After setting these environment variables, you can run the `azd up` command to deploy the app.

</details>
