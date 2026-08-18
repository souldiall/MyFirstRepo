locals {
  bucket_names = {
    for env in var.envs :
    env => "soul-${env}-bucket"
  }

  readme_content = {
    dev = <<-HTML
      <h1>DEV Bucket</h1>
      <p>This is the development bucket for application testing and preview artifacts.</p>
    HTML
    staging = <<-HTML
      <h1>STAGING Bucket</h1>
      <p>This is the staging bucket for pre-production validation and deployment checks.</p>
    HTML
    prod = <<-HTML
      <h1>PROD Bucket</h1>
      <p>This is the production bucket for live application artifacts and releases.</p>
    HTML
  }
}

