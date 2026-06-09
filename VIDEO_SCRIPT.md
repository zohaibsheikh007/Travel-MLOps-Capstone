# Video Presentation Script (15 - 40 min)

The capstone brief asks for **at least 15 minutes**, ideally 40, focused on the **regression** model and the full MLOps stack around it. Below is a section-by-section script you can read mostly word-for-word. Time estimates are conservative — feel free to slow down for screenshots.

> Recording tip: open OBS / Loom and screen-share. Have these tabs pre-loaded:
> 1. The GitHub repo
> 2. The notebook in Colab
> 3. The Flask form at `http://localhost:8000`
> 4. Airflow at `http://localhost:8080`
> 5. MLflow at `http://localhost:5000`
> 6. Streamlit apps (gender + hotel)

---

## Section 1 — Introduction (1.5 min)

> "Hi, I'm Zohaib Sheikh and this is my MLOps capstone — TravelWise, an end-to-end machine learning system for the travel and tourism domain. It does three things: it predicts flight prices, it classifies traveller demographics, and it recommends hotels. The whole project is structured around the MLOps lifecycle, so beyond the modelling itself I built a Flask REST API, packaged it in Docker, scaled it on Kubernetes, scheduled retraining with Apache Airflow, tracked experiments in MLflow, set up a CI/CD pipeline with both Jenkins and GitHub Actions, and shipped two interactive Streamlit applications. Today I'll walk through every one of those layers using the regression model — flight price prediction — as the running example."

## Section 2 — Problem Understanding (2 min)

> "Why machine learning for travel? Travel companies live and die by pricing accuracy and personalisation. A pricing model that's even five percent off costs millions in lost margin or lost bookings; a recommender that fits a user's history converts at three to five times the rate of generic listings. So the business case is clear.
> 
> But the more important point for this project is *why production matters*. A notebook that achieves 99% accuracy is worthless if it can't answer a request in 200 ms behind a load balancer, if there's no way to retrain it when the data drifts, and if there's no audit trail for the model that priced last Tuesday's bookings. Productionising the model is what turns a notebook experiment into a real business asset.
> 
> The four problems my system solves are: real-time price prediction, user demographic classification, personalised hotel recommendations, and the orchestration glue that lets all of them be retrained, redeployed, and monitored on a schedule."

## Section 3 — Data Understanding (2 min)

> "The dataset is the standard travel benchmark — three CSVs that link via two foreign keys, `userCode` and `travelCode`.
> 
> `users.csv` has 1,340 rows: code, company, name, gender, age. This feeds the gender classifier.
> 
> `flights.csv` has 271,888 rows: travelCode, userCode, from, to, flightType, price, time, distance, agency, date. This feeds the regression model — the one I'll build out today.
> 
> `hotels.csv` has 40,552 rows: travelCode, userCode, name, place, days, price, total, date. This feeds the recommender.
> 
> The link is straightforward: `userCode` joins users back to either flights or hotels; `travelCode` lets you reconstruct an entire trip — the user who took it, the flights they booked, the hotels they stayed at. So a more advanced version of this system would use joined features, but for the base capstone each model is trained on its own table.
> 
> One important EDA finding I want to flag — *show the notebook cell with `group_std.mean()` of zero*. Inside every from-to-flight-class-agency bucket the price standard deviation is zero. That tells me the dataset uses a deterministic pricing rule, which has consequences for the modelling section."

## Section 4 — Model Development (2.5 min)

> "*Open the notebook.* For feature engineering I drop the identifiers — travelCode, userCode — and the time/distance columns because they're collinear with the route. From the date I extract week number, day of week, day of month, and month. The four categorical features get one-hot encoded, and everything is standard-scaled.
> 
> *Scroll to the leaderboard.* I trained four model classes for comparison. Linear regression hits R-squared 0.64 — it can't capture the route-by-class interaction. A single decision tree with depth 12 lifts that to 0.90. Gradient boosting with 100 estimators and depth 4 reaches 0.94. Random forest with 100 trees gets near-perfect 1.0 — and that's *expected*, not a leak, because the underlying pricing is deterministic per group. We pick the random forest for production because it generalises across the date features and serves predictions in under five milliseconds.
> 
> *Switch to the Flask app code.* That trained pickle is loaded by `Flight_Price.py` at startup. There's a `/api/predict` POST endpoint that takes a JSON body, builds the feature vector, runs the scaler and the model, and returns the predicted price as JSON. There's also a `/health` endpoint for the load balancer.
> 
> *Switch to the form.* Here's the request-response flow live: I pick origin Sao Paulo, destination Rio, economic, CloudFy, week 10, day 15 — submit — predicted price 459 dollars. That round-trip is what every other piece of the MLOps stack supports."

## Section 5 — MLOps Pipeline (2 min)

> "Now the production layers, top to bottom.
> 
> **Docker** packages the API. The Dockerfile starts from python:3.11-slim, copies the code, installs requirements, exposes port 8000, and runs gunicorn with two workers. *Show `docker images`.* That image is what gets shipped.
> 
> **Kubernetes** runs two replicas of that image with liveness and readiness probes hitting `/health`. *Show `kubectl get pods`.* When traffic spikes, Kubernetes scales horizontally; when one pod crashes, the probe catches it and a fresh one comes up.
> 
> **Apache Airflow** *show the DAG view.* The pipeline has three tasks chained: extract, transform, train. Schedule is daily. Every run produces a fresh `random_forest.pkl` and writes it to a shared volume so the next deploy of the API picks up the new weights.
> 
> **MLflow** *show the experiments page.* Every Airflow training run and every notebook run logs RMSE, MAE, R-squared, the parameters, and the model artifact. The model registry lets us roll back to a previous version with one click.
> 
> **Jenkins** and **GitHub Actions** are the two CI/CD options I shipped. *Show the GitHub Actions tab.* On every push to main: install, train, test, build the Docker image, push to Docker Hub, then update the Kubernetes manifest with the new image tag and commit it back. So a developer pushes Python code, and twenty minutes later there's a new version of the API running in the cluster — fully automated."

## Section 6 — Streamlit + Recommendation (2 min)

> "*Open the gender app.* The gender classifier is logistic regression on TF-IDF character n-grams of the user's name plus standardised age, code, and company. Tuned with grid search, it gets seventy percent accuracy and 0.74 AUC. Streamlit gives operations a self-service way to look up a user.
> 
> *Open the hotel app.* The hotel recommender is collaborative filtering by truncated SVD on a user-by-hotel matrix where the rating is total spend. *Pick a user, click recommend.* These five hotels have the highest latent affinity scores — they would be the personalised top five if this user logged in tomorrow.
> 
> Both Streamlit apps are deliberately simple — they're proofs that the modelling layer can be consumed by non-technical users without any code."

## Section 7 — Reliability and Challenges (1.5 min)

> "Three real challenges I hit:
> 
> One — the dataset's deterministic pricing meant the random forest got near-perfect R-squared. That looked suspicious until I dug into the EDA and confirmed the underlying rule. The fix was honest documentation in the notebook plus a four-model leaderboard so the comparison story is meaningful.
> 
> Two — designing the API contract. I went with a JSON body over form-encoded because every downstream client (mobile, web, partner integrations) expects JSON. I added a separate HTML form for manual testing and an isolated `/health` endpoint for Kubernetes — that separation keeps the prediction path lean.
> 
> Three — Airflow plus MLflow plus Postgres in one docker-compose was finicky. I solved it with an init script that creates the `mlflow_db` database before the MLflow service starts.
> 
> Reliability comes from version control: every model is logged to MLflow, every Docker image is tagged with the commit SHA, every K8s deployment is reproducible from the YAML in the repo. If anything breaks I can roll back any single layer without touching the others."

## Section 8 — Learnings and Future Work (1.5 min)

> "Three things I learned. First, training a model is the easy part — the production scaffolding around it is roughly five times the code. Second, the boundary between teams matters as much as the architecture: a clean REST contract is what lets the data scientist iterate without breaking the front-end. Third, observability isn't a feature, it's a prerequisite — without MLflow I'd have no way to defend a price estimate from last week.
> 
> Future work I'd ship next: model monitoring with Evidently to catch drift, an automatic retraining trigger on drift threshold, OAuth2 on the Flask API, hybrid recommendations using LightFM with side-information, and a managed cloud deployment with autoscaling.
> 
> That's the full system. Thank you."

---

## Cheat sheet for the demo

If you only have 15 minutes, cut sections 6 and 7 down to 30 seconds each — keep modelling and pipeline sections at full length.

If you have 40 minutes, expand:
- Section 4 — open the notebook and walk through every code cell, not just the leaderboard.
- Section 5 — open each YAML and walk through what it does.
- Section 6 — show all three apps running side-by-side.

The most important thing is to have the screens already loaded. The script is the safety net; the live demos are what convinces the examiner.
