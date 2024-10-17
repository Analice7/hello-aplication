# Stage 1: Build
FROM python:3.9-slim AS build

# Set the working directory inside the container
WORKDIR /app 

# Copy the requirements file to the working directory
COPY requirements.txt . 

# Install the dependencies listed in 'requirements.txt'
RUN pip install --no-cache-dir -r requirements.txt 

# Stage 2: Final Image
FROM python:3.9-slim 

# Set the working directory in the new image
WORKDIR /app 

# Copy all installed packages from the 'build' stage
COPY --from=build /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

# Copy the main application file to the working directory
COPY app.py . 

# Expose the port the app will run on
EXPOSE 5000

# Define the command to be executed when the container starts
CMD ["python", "app.py"] 
