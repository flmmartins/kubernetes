# Immich

## Data migration
I had to do a data migration and I saw that if you delete a pod because the other one is starting it can crash the migration. Even if pod is erroring: let it do it's thing and add one and later remove the other automatically. Do not touch!

## Library
It expects data to be in uploaded folder inside it's library mount however I didn't want to move all my photos so I added my photos as an **external** library.

### Memory issues on first scan
Here is a set of settings I used to low memory usage and pods from being killed:

**Reduce job concurrency**

Go to Administration → Jobs and set concurrency to 1 for every job specially ML-heavy:

Smart Search
Face Detection
Facial Recognition
Video Transcoding

**Machine learn model**

Machine Learning Settings → Facial Recognition → Model Name, switch from buffalo_l to buffalo_s

**Machine learnin pod**

Add some environment variables to the pod

### Automatic Scans
I set it to monitor file changes but also on Administration > Settings >  External Library > Periodic Scanner and I put a cronjob that doesn't clash wit other jobs I ran

## Config
Open first start it asked how I wanted to organize photos
