'use client'

import { useRef } from 'react'
import { Button } from '@/components/ui/button'
import { FileText, BookOpen } from 'lucide-react'

export function QuestionBankActions({ schoolId }: { schoolId: string | null }) {
  const fileInputRef = useRef<HTMLInputElement>(null)

  async function handleImport(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    // TODO: Parse CSV/JSON and call import action
    console.log('Import file:', file.name)
  }

  function handleExport() {
    window.open('/api/questions/export', '_blank')
  }

  return (
    <>
      <Button variant="outline" className="gap-2" onClick={() => fileInputRef.current?.click()}>
        <FileText className="h-4 w-4" />
        Import
      </Button>
      <Button variant="outline" className="gap-2" onClick={handleExport}>
        <BookOpen className="h-4 w-4" />
        Export
      </Button>
      <input
        ref={fileInputRef}
        type="file"
        accept=".csv,.json"
        className="hidden"
        onChange={handleImport}
      />
    </>
  )
}
