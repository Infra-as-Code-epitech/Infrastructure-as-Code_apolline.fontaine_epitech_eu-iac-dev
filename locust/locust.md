1.  **Start Locust:**

    ```bash
    # Replace with your Load Balancer URL (HTTPS)
    locust -f locustfile.py --host https://your-load-balancer-url.elb.amazonaws.com
    ```

2.  **Open Dashboard:**
    Go to `http://localhost:8089` in your browser.

3.  **Configure the Test:**
    - **Number of users (peak concurrency):** Start with **200**.
    - **Spawn rate (users started/second):** Set to **10**.
    - Click **Start Swarming**.

### 4. Running the Test (Headless / High Load)

If you want to trigger HPA quickly, you need to hammer the API without the UI overhead.

Run this in your terminal:

```bash
# -u 300: 300 concurrent users
# -r 50: Add 50 users per second (fast ramp up)
# -t 10m: Run for 10 minutes
locust -f locustfile.py --headless \
  -u 300 -r 50 -t 10m \
  --host https://your-load-balancer-url.elb.amazonaws.com
```

### 5. Watching the Scale Up

While Locust is running, open a separate terminal to watch Kubernetes react.

**1. Watch HPA:**
You should see the `%` jump over 50%, and `REPLICAS` increase.

```bash
kubectl get hpa -n app -w
```

**2. Watch Cluster Autoscaler:**
When HPA requests more pods than your nodes can fit, you will see `Pending` pods, followed by a new Node joining.

```bash
kubectl get pods -n app -o wide -w
# In another tab:
kubectl get nodes -w
```
