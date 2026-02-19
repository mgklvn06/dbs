const String kMpesaBackendBaseUrl = String.fromEnvironment(
  'MPESA_BACKEND_BASE_URL',
  defaultValue: '',
);

const String kMpesaStkPushEndpointPath = '/stkpush';
const String kMpesaTransactionEndpointPath = '/transactions';
