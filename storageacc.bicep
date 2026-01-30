@description('Name of the Storage Account. Must be globally unique, 3-24 chars, lowercase letters and numbers.')
param storageAccountName string

@description('Azure region for the Storage Account (must match the RG location when deploying at RG scope).')
param location string = resourceGroup().location

@description('Redundancy SKU.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param skuName string = 'Standard_LRS'

@description('Enable hierarchical namespace (Data Lake Storage Gen2).')
param enableHns bool = false

@description('Allow public network access to the storage endpoint. If Disabled, use private endpoints.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Default network rule for public access. Deny if you want to allow only selected networks/IPs.')
@allowed([
  'Allow'
  'Deny'
])
param defaultAction string = 'Allow'

@description('List of IPv4 CIDR ranges to allow when defaultAction = Deny.')
param ipRules array = []

@description('Minimum TLS version.')
@allowed([
  'TLS1_2'
  'TLS1_1'
  'TLS1_0'
])
param minTlsVersion string = 'TLS1_2'

@description('Enable Soft Delete for Blob service (in days). Set 0 to disable.')
@minValue(0)
@maxValue(365)
param blobDeleteRetentionDays int = 14

@description('Enable Container soft delete (in days). Set 0 to disable.')
@minValue(0)
@maxValue(365)
param containerDeleteRetentionDays int = 7

@description('Enable versioning for blobs.')
param blobVersioningEnabled bool = true

@description('Block public access to blobs and containers.')
param blockBlobPublicAccess bool = true

@description('Enable SFTP (requires HNS).')
param isSftpEnabled bool = false

@description('Enable NFS v3 (requires HNS, Premium/ZRS not supported in all regions).')
param isNfsV3Enabled bool = false

resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: enableHns ? 'StorageV2' : 'StorageV2'
  properties: {
    allowBlobPublicAccess: !blockBlobPublicAccess // property name indicates "allow"; we pass false to block
    minimumTlsVersion: minTlsVersion
    publicNetworkAccess: publicNetworkAccess
    supportsHttpsTrafficOnly: true
    largeFileSharesState: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: defaultAction
      ipRules: [
        for cidr in ipRules: {
          action: 'Allow'
          value: cidr
        }
      ]
      virtualNetworkRules: [] // add VNets if needed
    }
    encryption: {
      services: {
        file: { keyType: 'Account', enabled: true }
        blob: { keyType: 'Account', enabled: true }
      }
