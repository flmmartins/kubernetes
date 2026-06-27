# Immich

## Photo Library
It expects data to be in immich-config folder inside it's library mount however I didn't want to move all my photos because there's so many and it usually takes a long time to move all files so I added my photos as an **external** library.

## What happens with phone uploads
Automatic phone uploads are added into immich-config/library folder and there's no way to configure this to put in my external photo library outside immich-config. So I ended up moving immich config folder inside my photo library. So now you have a mix of photos with it's own folders + immich-config/library which contains other photos.
It is a bit messy but it is what it is.

I had to exclude the folder from immich automatic scans so it doesn't think faces for example are photos so I had to go to  Administration → External Libraries → your library → Exclusion Patterns → Add → `**/immich-config/**`

## Data migration of PVs
I had to do a data migration and I saw that if you delete a pod because the other one is starting it can crash the migration. Even if pod is erroring: let it do it's thing and add one and later remove the other automatically. Do not touch!

## Stopping immich from being killed during big scans
Here is a set of settings I used to low memory usage and pods from being killed:

**Reduce job concurrency**

Go to Administration → Jobs and set concurrency to 1 for every job specially ML-heavy:

Smart Search
Face Detection
Facial Recognition
Video Transcoding

**Machine learn model**

Machine Learning Settings → Facial Recognition → Model Name, switch from buffalo_l to buffalo_s

**Machine learning pod**

Add some environment variables to the pod

### Automatic Scans
I set it to monitor file changes but also on Administration > Settings >  External Library > Periodic Scanner and I put a cronjob that doesn't clash wit other jobs I ran

## Album
Open first start it asked how I wanted to organize photos I choose a storage migration with album name YEAR/ALBUM. If there's no album name it will be stored as YEAR/OTHER

### Album config on external library
On first initialization of immich it recognize the files but not the folders on it to create the albums. So I added a cronjob that will periodically create albuns based on external library if someone instead of using immich just dump the photos in the file share and create an album folder

### Album config on immich
If person does not create folder on external library or do an automatic phone upload this obsviously will not create an album. The creation of the album has to be made inside the platform
