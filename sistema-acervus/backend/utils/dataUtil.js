function parseDateBRtoISO(dateStr) {
  if (!dateStr) return null;
  const [dia, mes, ano] = dateStr.split('/');
  return `${ano}-${mes}-${dia}`; // formato ISO
}