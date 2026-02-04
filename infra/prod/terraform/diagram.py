"""
Architecture diagram for the production EKS infrastructure.

Generate the diagram:
    pip install diagrams
    python diagram.py

This creates architecture.png in the current directory.
"""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EKS
from diagrams.aws.network import VPC, NATGateway, ElasticLoadBalancing
from diagrams.aws.storage import S3
from diagrams.k8s.compute import Pod
from diagrams.k8s.network import Service
from diagrams.saas.cdn import Cloudflare
from diagrams.onprem.vcs import Github
from diagrams.onprem.certificates import LetsEncrypt

with Diagram(
    "Production Architecture",
    filename="architecture",
    show=False,
    direction="TB",
):
    internet = ElasticLoadBalancing("NLB")
    cloudflare = Cloudflare("DNS + TLS")
    github = Github("GitOps")
    s3 = S3("csv-uploader-ounass")

    with Cluster("AWS VPC"):
        with Cluster("EKS Cluster"):
            with Cluster("Platform"):
                flux = Pod("Flux CD")
                karpenter = Pod("Karpenter")
                gateway = Service("Gateway")

            with Cluster("Applications"):
                csv_uploader = Pod("csv-uploader")
                panda = Pod("panda-secret")

    internet >> gateway >> [csv_uploader, panda]
    csv_uploader >> s3
    flux >> Edge(label="sync") >> github
    cloudflare >> Edge(label="DNS") >> internet
