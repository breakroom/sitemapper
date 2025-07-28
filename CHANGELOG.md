# Changelog

### 0.10.0

- Added support for images (thanks @rafal0p)

### 0.9.0

- Fixed compilation when `ex_aws_s3` or `google_api_storage` dependencies aren't available - you can now use Sitemapper without these dependencies in your project

### 0.8.1

- Add support for storing sitemaps on GCP Storage, with `Sitmapper.GCPStorageStore`

### 0.8.0

- Remove support for `Sitemapper.ping` as neither Google nor Bing support pinging sitemaps any more.

### 0.7.0

- Always return files as binaries - previously, when gzip was disabled, file
  content was in the form of IO data, which `Sitemapper.S3Store` would choke on.
  If you have your own implementation of `Sitemapper.Store`, this may be a
  breaking change for you.
