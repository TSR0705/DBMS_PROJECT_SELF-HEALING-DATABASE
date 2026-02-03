interface SectionProps {
  title: string;
  description?: string;
  children: React.ReactNode;
  className?: string;
}

// Professional section container with clean, technical design
export function Section({
  title,
  description,
  children,
  className = '',
}: SectionProps) {
  return (
    <section className={`mb-8 ${className}`}>
      <header className="mb-6">
        <h2 className="text-xl font-bold text-slate-900 mb-2">{title}</h2>
        {description && (
          <p className="text-sm text-slate-600 leading-relaxed">
            {description}
          </p>
        )}
        <div className="mt-4 h-px bg-slate-200" />
      </header>

      <div>{children}</div>
    </section>
  );
}
