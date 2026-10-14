"use client";

import { useState } from "react";
import { Sidebar } from "./sidebar";
import { BottomNav } from "./bottom-nav";
import { UploadDocumentDialog } from "@/components/documents/upload-dialog";

export function AppShell({ children }: { children: React.ReactNode }) {
  const [uploadOpen, setUploadOpen] = useState(false);

  return (
    <div className="flex min-h-screen w-full">
      <Sidebar onAddDocument={() => setUploadOpen(true)} />
      <main className="flex-1 pb-20 md:pb-0">{children}</main>
      <BottomNav onAddDocument={() => setUploadOpen(true)} />
      <UploadDocumentDialog open={uploadOpen} onClose={() => setUploadOpen(false)} />
    </div>
  );
}
