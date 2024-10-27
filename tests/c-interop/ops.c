unsigned char fade(unsigned char a, float alpha) {
  if (alpha < 0.0f)
    alpha = 0.0f;
  else if (alpha > 1.0f)
    alpha = 1.0f;

  return (unsigned char)(a * alpha);
}
