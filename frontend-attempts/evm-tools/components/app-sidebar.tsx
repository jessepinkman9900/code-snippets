'use client'

import { 
  SidebarGroup, 
  SidebarHeader, 
  SidebarContent, 
  Sidebar, 
  SidebarMenuButton, 
  SidebarGroupLabel, 
  SidebarFooter, 
  SidebarGroupContent,
  SidebarMenuItem,
  SidebarMenu
} from "@/components/ui/sidebar";
import { Calendar, Home } from "lucide-react";
import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";

const items = [
  {
    href: "rpc-client",
    title: "rpc client",
    url: "",
    icon: Home
  },
  {
    href: "rpc-checker",
    title: "rpc checker",
    url: "",
    icon: Calendar
  }
]

export default function AppSidebar() {
  const [sidebarItem, setSidebarItem] = useState<string>("rpc-client")
  const pathname = usePathname()

  return (
    <Sidebar>
      <SidebarHeader />
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>evm tools</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {items.map((item) => {
                const isActive = pathname.includes(item.href)
                return (
                  <SidebarMenuItem key={item.href}>
                    <SidebarMenuButton asChild isActive={isActive}>
                      <Link key={item.href} href={item.href}>
                        <item.icon />
                        <span>{item.title}</span>
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                )
              })}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter />
    </Sidebar>
  );
}
