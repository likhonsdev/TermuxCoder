# Build and Deployment Documentation

This document outlines the steps for building and deploying the TermuxCoder project.

## Building

The project requires Node.js and npm (or yarn) to be installed.

1.  **Install Dependencies:**
    Navigate to the project root directory and run:
    ```bash
    npm install
    ```
    or
    ```bash
    yarn install
    ```

2.  **Build the Frontend:**
    To build the frontend assets for production, run:
    ```bash
    npm run build
    ```
    This will generate the build files in the `dist` directory.

3.  **Docker Build:**
    Alternatively, you can build a Docker image of the application using the provided `Dockerfile`:
    ```bash
    docker build -t termuxcoder .
    ```

## Deployment

There are several ways to deploy the TermuxCoder project:

1.  **Running Directly:**
    You can start the backend server directly using Node.js:
    ```bash
    npm start
    ```
    Ensure you have built the frontend first (`npm run build`).

2.  **Docker Compose (Development):**
    For a development deployment using Docker, you can use Docker Compose:
    ```bash
    docker-compose up
    ```
    This will build the image (if not already built) and start the container, mapping port 3000.

3.  **Docker (Production):**
    For a production deployment using Docker, first build the image (as shown in the Building section), then run the container:
    ```bash
    docker run -d -p 3000:3000 termuxcoder
    ```

4.  **Vercel:**
    The project includes a `vercel.json` file, suggesting it can be deployed to Vercel. Refer to the Vercel documentation for detailed instructions on deploying Node.js applications.
