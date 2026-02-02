interface SectionProps {
  title: string;
  description?: string;
  children: React.ReactNode;
  className?: string;
}

// Console section container - clear framing without card aesthetics
export function Section({
  title,
  description,
  children,
  className = '',
}: SectionProps) {
  return (
    <section className={`mt-8 first:mt-0 ${className}`}>
      <header className="mb-4">
        <h2 className="text-lg font-medium text-neutral-900 mb-1">{title}</h2>
        {description && (
          <p className="text-sm text-neutral-600 leading-relaxed">
            {description}
          </p>
        )}
        <div className="mt-3 h-px bg-neutral-200" />
      </header>

      <div className="mt-6">{children}</div>
    </section>
  );
}
