# M3 Hosted Reference Data Collections

M3 hosts copies of several common reference datasets and large data collections. Some require registering acceptance of terms before access is granted. For details on how to register and access them, see the [official Data Collections documentation](https://docs.erc.monash.edu/Compute/HPC/M3/DataCollections/).

### Common hosted datasets and locations

| Dataset | Category | Location on M3 | Access requirement / notes |
|---------|----------|----------------|----------------------------|
| **ImageNet 2012 (ILSVRC2012)** | Machine Learning | `/mnt/datasets/imagenet` | Accept terms on HPC ID/Karaage portal |
| **ImageNet 2015 Object Detection** | Machine Learning | `/mnt/datasets/imagenet/imagenet-2015-det` | Accept terms on HPC ID/Karaage portal |
| **ISIC 2019** | Machine Learning | `/mnt/datasets/isic-2019` | Register request on HPC ID/Karaage portal |
| **SNLI Corpus** | Machine Learning | `/mnt/datasets/snli-corpus` | Accept terms on HPC ID/Karaage portal |
| **COCO 2017** | Machine Learning | `/mnt/datasets/coco-2017` | Accept terms on HPC ID/Karaage portal. Note: large dirs are split into subdirs of ~40k files to reduce filesystem strain. |
| **dHCP (Developing Human Connectome)** | Neuroimaging | `/mnt/datasets/developing_hcp` | Register at dHCP database, then forward approval email to support and request on HPC portal |
| **Baby Connectome Project** | Neuroimaging | `/mnt/datasets/hcp-ccf/hcp_baby/hcp_baby_20211210` | Restricted. Submit Data Use Certificate (DUC) from NDA to support |
| **HCP for Early Psychosis** | Neuroimaging | `/mnt/datasets/hcp-ccf/hcp_ep/hcp_ep_v1.1` | Restricted. Submit DUC from NDA to support |
| **Brain Genomics Superstruct (GSP)** | Neuroimaging | `/fs04/scratch2/gsp/gsp-20200910` | Request access on Harvard Dataverse, forward approval email to support and request on HPC portal. Symlink to `~/` is recommended. |
| **NKI Rockland Sample (NKI-RS)** | Neuroimaging | `/fs04/scratch2/nkirs-ndr/RawDataBidsLatest_20200819` | Register request on HPC ID portal. Symlink to `~/` is recommended. |

### Requesting new datasets
To request MASSIVE to host a new community reference dataset, email `help@massive.org.au` with:
1. Dataset name
2. Download URL
3. Data size
4. Urgency
5. Ethics or licensing restrictions
6. Details of the research community that will use it
