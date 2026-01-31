import { Separator } from "@/components/ui/separator";

interface SectionProps {
  title: string;
  description?: string;
  children: React.ReactNode;
  className?: string;
}

// Modern section container with sophisticated visual hierarchy
export function Section({ title, description, children, className = "" }: SectionProps) {
  return (
    <section className={`space-y-6 ${className}`}>
      <header className="space-y-3">
        <div className="flex items-center space-x-4">
          <div className="flex-1">
            <h2 className="text-xl font-bold text-slate-900 tracking-tight">
              {title}
            </h2>
            {description && (
              <p className="text-sm text-slate-600 leading-relaxed mt-2 max-w-2xl">
                {description}
              </p>
            )}
          </div>
          <div className="w-12 h-px bg-gradient-to-r from-slate-300 to-transparent" />
        </div>
      </header>
      
      <div className="space-y-6">
        {children}
      </div>
    </section>
  );
}