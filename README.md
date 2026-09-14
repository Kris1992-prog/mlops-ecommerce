# Progetto MLOps & Cloud-Native Infrastructure

Un'architettura MLOps e Cloud-Native end-to-end progettata per simulare standard di livello enterprise. Il progetto unisce il provisioning automatizzato del cloud, pratiche di FinOps, pipeline di CI/CD e la containerizzazione di microservizi di machine learning su Kubernetes.

## 🌟 Caratteristiche Principali
- **Infrastructure as Code (IaC):** Gestione dichiarativa e riproducibile delle risorse cloud su AWS tramite Terraform.
- **FinOps & Cost Governance:** Controllo preventivo dei costi implementato con AWS Budgets e policy di pulizia automatica per i bucket S3.
- **CI/CD Automation:** Pipeline configurate in GitHub Actions per automatizzare i test, la validazione e il deployment dell'infrastruttura.
- **Orchestrazione dei Container:** Deploy di microservizi basati su FastAPI e gestione di task di machine learning all'interno di un cluster Kubernetes.
- **Resilienza e Profilo Locale (8 GB RAM):** Architettura modulare progettata per operare in modo efficiente anche su ambienti di sviluppo locali con vincoli hardware ristretti.

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

### 1. Inizializza e verifica Terraform
    cd environments/dev
    terraform init
    terraform plan

### 2. Deploy su Kubernetes (Minikube)
Applica le configurazioni nel namespace dedicato `ml`:
    kubectl apply -f k8s/ -n ml

## 📊 Stato Attuale e Profilo di Sviluppo Locale (8 GB RAM)
L'architettura è progettata per essere flessibile: in ambienti di sviluppo locali con risorse hardware limitate (es. 8 GB RAM su Minikube), i microservizi possono essere gestiti in modo modulare:

| Componente | Stato / Ruolo | Dettagli di Configurazione |
| :--- | :--- | :--- |
| **FastAPI Recommendation API** | `1/1 Running` | Microservizio core di inferenza che scarica dinamicamente il modello `model.joblib` dal bucket S3 (`kris-ecommerce-ml-dev`) |
| **MySQL Database** | `1/1 Running` | Storage relazionale per catalogo prodotti e raccomandazioni |
| **AWS S3 (`kris-ecommerce-ml-dev`)** | `Attivo` | Object storage remoto per il versioning del modello ML |
| **Ollama LLM Service** | `Modulare / Facoltativo` | Layer conversazionale (`qwen2.5:0.5b`) — può essere scalato a `0` o rimosso in locale per liberare RAM (`kubectl delete pod ollama-0 -n ml`) |

### 🔍 Verifica Locale dell'Applicazione
Per testare il servizio in esecuzione tramite port-forward:
    kubectl port-forward -n ml service/ecommerce-service 8000:8000

- **Health Check:** `http://localhost:8000/health`
- **Readiness Check:** `http://localhost:8000/ready`
- **Documentazione Interattiva (Swagger UI):** `http://localhost:8000/docs`