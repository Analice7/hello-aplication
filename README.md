# Hello World Application

Este projeto é uma aplicação simples em Python que responde com "Hello World" em um endpoint. O foco deste repositório é demonstrar como containerizar uma aplicação usando Docker, incluindo um Dockerfile com build multi-stage, além de implementar uma pipeline CI/CD para automatizar o processo de construção e envio da imagem Docker.

## Estrutura do Projeto

```
hello-application/
├── hello-app/
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── deployment.yml
│   └── service.yml
└── .github/
    └── workflows/
        └── main.yml
```

### Empacotamento da Aplicação Python

Neste projeto, criaremos uma aplicação simples que retorna "Hello World" usando Flask e a empacotaremos com Docker.

### Dockerização da Aplicação Python

#### 1. Dockerfile: Build Multi-stage

O uso de multi-stage build ajuda a otimizar o tamanho da imagem final:

```dockerfile
# Imagem base para construção
FROM python:3.9-slim AS build

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Fase final: imagem mínima
FROM python:3.9-slim

WORKDIR /app

COPY --from=build /app .

EXPOSE 5000

CMD ["python", "app.py"]
```

**Explicação do Dockerfile Multi-stage:**
- `FROM python:3.9-slim AS build`: Define a primeira fase de build, usando a imagem base do Python 3.9.
- `WORKDIR /app`: Define o diretório de trabalho para a construção.
- `COPY requirements.txt .`: Copia o `requirements.txt` para a fase de build.
- `RUN pip install --no-cache-dir -r requirements.txt`: Instala as dependências.
- `COPY app.py .`: Copia o código da aplicação.
- `FROM python:3.9-slim`: Inicia uma nova fase para a imagem final.
- `COPY --from=build /app .`: Copia os arquivos da fase de build para a nova imagem, mantendo apenas o necessário para a execução.
- `EXPOSE 5000`: Expõe a porta 5000.
- `CMD ["python", "app.py"]`: Define o comando de execução da aplicação.

### Configuração do Kubernetes

#### 1. Deployment

O arquivo `hello-app/deployment.yml` define como o Kubernetes gerencia a aplicação:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-app
  template:
    metadata:
      labels:
        app: hello-app
    spec:
      containers:
      - name: hello-app
        image: analicesilva/hello-app
        ports:
        - containerPort: 5000
```

**Explicação do Deployment:**
- `replicas`: Define que queremos uma instância (replica) do pod.
- `selector`: Utiliza um rótulo para identificar o pod gerenciado.
- `template`: Especifica a configuração do pod, incluindo a imagem Docker a ser usada.

#### 2. Service

O arquivo `hello-app/service.yml` expõe a aplicação para acesso externo:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-app
spec:
  type: NodePort
  ports:
    - port: 5000
      targetPort: 5000
      nodePort: 30000
  selector:
    app: hello-app
```

**Explicação do Service:**
- `type`: Define o tipo como `NodePort`, permitindo acesso externo.
- `ports`: Mapeia a porta do serviço e a porta do container, com um `nodePort` definido para acesso externo.

### Pipeline com GitHub Actions

A seguir, um exemplo de pipeline que constrói a imagem da aplicação e a envia para o Docker Hub automaticamente.

#### Arquivo `.github/workflows/main.yml`

```yaml
name: Docker Image CI/CD

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Login to Docker Hub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Build and push
      uses: docker/build-push-action@v6
      with:
        context: ./hello-app
        file: ./hello-app/Dockerfile
        push: true
        tags: ${{ secrets.DOCKERHUB_USERNAME }}/hello-app:latest
```

**Explicação da Pipeline:**
- `name: Docker Image CI/CD`: Nome da ação, que aparece nas interfaces do GitHub.
- `on: push: branches: - main`: Define que a pipeline é acionada em um push na branch `main`.
- `jobs`: Define os trabalhos a serem executados na pipeline.
- `build`: Nome do trabalho que realiza a construção da imagem Docker.
- `runs-on: ubuntu-latest`: Especifica o ambiente onde o trabalho será executado, utilizando a última versão do Ubuntu.

**Etapas da Pipeline:**
1. **Checkout do Código**
   ```yaml
   - name: Checkout code
     uses: actions/checkout@v3
   ```
   - Esta etapa utiliza a ação oficial do GitHub para realizar o checkout do código do repositório, garantindo que o código-fonte mais recente esteja disponível.

2. **Login no Docker Hub**
   ```yaml
   - name: Login to Docker Hub
     uses: docker/login-action@v3
     with:
       username: ${{ secrets.DOCKERHUB_USERNAME }}
       password: ${{ secrets.DOCKERHUB_TOKEN }}
   ```
   - Realiza o login no Docker Hub utilizando credenciais armazenadas como segredos, permitindo que a pipeline tenha permissão para enviar a imagem construída.

3. **Construir e Enviar a Imagem**
   ```yaml
   - name: Build and push
     uses: docker/build-push-action@v6
     with:
       context: ./hello-app
       file: ./hello-app/Dockerfile
       push: true
       tags: ${{ secrets.DOCKERHUB_USERNAME }}/hello-app:latest
   ```
   - Esta etapa utiliza a ação para construir e enviar a imagem Docker, especificando o contexto e o caminho do Dockerfile. A imagem é enviada para o Docker Hub.

### Aplicação Python de Exemplo

A aplicação Python utilizada neste projeto é um simples "Hello World" que responde na porta 5000.

```python
from flask import Flask

app = Flask(__name__)

@app.route('/message')
def hello():
    return "Hello World"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**Explicação do Código da Aplicação:**
- `from flask import Flask`: Importa a classe Flask da biblioteca Flask.
- `app = Flask(__name__)`: Cria uma instância da aplicação Flask.
- `@app.route('/message')`: Define uma rota `/message` que responde a requisições HTTP.
- `def hello()`: Define a função que será chamada quando a rota `/message` for acessada.
- `return "Hello World"`: Retorna a string "Hello World" como resposta.
- `if __name__ == '__main__': app.run(host='0.0.0.0', port=5000)`: Inicia a aplicação Flask quando o script é executado diretamente, ouvindo na porta 5000.

## Conclusão

Neste projeto, abordamos desde a criação de uma aplicação Python simples até a sua containerização com Docker e a implementação de uma pipeline CI/CD utilizando GitHub Actions. Também configuramos um Deployment e um Service no Kubernetes para gerenciar e expor a aplicação. Essa abordagem automatiza o processo de construção e publicação da imagem Docker, permitindo uma integração contínua mais eficiente.
