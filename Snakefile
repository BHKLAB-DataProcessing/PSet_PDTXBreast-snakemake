from snakemake.remote.S3 import RemoteProvider as S3RemoteProvider
S3 = S3RemoteProvider(
    access_key_id=config["key"], 
    secret_access_key=config["secret"],
    host=config["host"],
    stay_on_remote=False
)
prefix = config["prefix"]
filename = config["filename"]
annotations_repo = config["annotations_repo"]

rule get_pset:
    input:
        S3.remote("bhklab_orcestra/annotation/drugs_with_ids.csv"),
        S3.remote(prefix + "breast/cell.csv"),
        S3.remote(prefix + "breast/cell_annotation_all.csv"),
        S3.remote(prefix + "breast/final_eset.Rda"),
        S3.remote(prefix + "breast/raw_drug.csv"),
        S3.remote(prefix + "drug_sensitivity/info.rds"),
        S3.remote(prefix + "drug_sensitivity/dose_viability.rds"),
        S3.remote(prefix + "drug_sensitivity/raw.rds"),
        S3.remote(prefix + "drug_sensitivity/profiles.rds")
    output:
        S3.remote(prefix + filename)
    shell:
        """
        Rscript scripts/getPDTX.R \
        {prefix}breast/ \
        {prefix}drug_sensitivity/ \
        bhklab_orcestra/annotation/ \
        {prefix} \
        {filename}
        """

rule normalize_and_compute_sens:
    input:
        S3.remote(prefix + "published_data/RawDataDrugsSingleAgents.txt"),
        S3.remote(prefix + "published_data/DrugResponsesAUCSamples.txt")
    output:
        S3.remote(prefix + "drug_sensitivity/info.rds"),
        S3.remote(prefix + "drug_sensitivity/dose_viability.rds"),
        S3.remote(prefix + "drug_sensitivity/raw.rds"),
        S3.remote(prefix + "drug_sensitivity/profiles.rds")
    shell:
        """
        Rscript scripts/sensitivity.R \
        {prefix}published_data/ \
        {prefix}drug_sensitivity/
        """

rule get_published_data:
    output:
        S3.remote(prefix + "published_data/RawDataDrugsSingleAgents.txt"),
        S3.remote(prefix + "published_data/DrugResponsesAUCSamples.txt")
    shell:
        """
        wget -O {prefix}published_data/16 https://figshare.com/ndownloader/articles/2069274/versions/16
        unzip -o {prefix}published_data/16 -d {prefix}published_data
        find {prefix}published_data ! -name 'RawDataDrugsSingleAgents.txt' ! -name 'DrugResponsesAUCSamples.txt' -type f -delete
        """
