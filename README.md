# Progetto MLOps & Cloud-Native Infrastructure

Un'architettura MLOps e Cloud-Native end-to-end progettata per simulare standard di livello enterprise. Il progetto unisce il provisioning automatizzato del cloud, pratiche di FinOps, pipeline di CI/CD e la containerizzazione di microservizi di machine learning su Kubernetes.

## 🌟 Caratteristiche Principali
- **Infrastructure as Code (IaC):** Gestione dichiarativa e riproducibile delle risorse cloud su AWS tramite Terraform.
- **FinOps & Cost Governance:** Controllo preventivo dei costi implementato con AWS Budgets e policy di pulizia automatica per i bucket S3.
- **CI/CD Automation:** Pipeline configurate in GitHub Actions per automatizzare i test, la validazione e il deployment dell'infrastruttura.
- **Orchestrazione dei Container:** Deploy di microservizi basati su FastAPI e gestione di task di machine learning all'interno di un cluster Kubernetes.

## 🛠️ Tecnologie Utilizzate
- **Cloud & IaC:** AWS (S3, ECR, IAM, Budgets), Terraform
- **Orchestrazione & Runtime:** Docker, Kubernetes (Minikube)
- **Automazione:** GitHub Actions (`terraform-ci.yml`, `terraform-cd.yml`)
- **Linguaggi & Framework:** Python, FastAPI

## 📂 Struttura del Progetto
- `.github/workflows/`: Pipeline di integrazione e distribuzione continua (CI/CD).
- `app/`: Codice sorgente dell'applicazione, API e relativi Dockerfile.
- `environments/dev/`: Configurazioni specifiche di Terraform per l'ambiente di sviluppo.
- `k8s/`: Manifest di Kubernetes per il deploy dei servizi e del cluster.
- `retrain/`: Script e logiche per l'addestramento e l'aggiornamento dei modelli ML.
- `budget.tf` & `cleanup_policies.tf`: Moduli dedicati al controllo dei costi e alla gestione dello storage AWS.

## 🚀 Come Eseguire il Progetto

1. **Inizializza e verifica Terraform:**
   ```bash
   cd environments/dev
   terraform init
   terraform plan