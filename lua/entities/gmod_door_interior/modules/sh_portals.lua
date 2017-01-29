-- Handles portals for rendering, thanks to bliptec (http://facepunch.com/member.php?u=238641) for being a babe

if SERVER then	
	ENT:AddHook("PlayerInitialize", "portals", function(self)
		if self.portals then
			net.WriteEntity(self.portals.exterior)
			net.WriteEntity(self.portals.interior)
			net.WriteInt(table.Count(self.customportals),8)
			for k,v in pairs(self.customportals) do
				net.WriteString(k)
				
				net.WriteEntity(v.entry)
				net.WriteBool(v.entry.black)
				
				net.WriteEntity(v.exit)
				net.WriteBool(v.exit.black)
			end
		end
	end)
	
	ENT:AddHook("PreInitialize", "portals", function(self)
		local int=self.Portal
		local ext=self.exterior.Portal
		if not (int and ext) then return end
		self.portals={}
		self.portals.exterior=ents.Create("linked_portal_door")
		self.portals.interior=ents.Create("linked_portal_door")
		
		self.portals.exterior:SetWidth(ext.width)
		self.portals.exterior:SetHeight(ext.height)
		self.portals.exterior:SetPos(self.exterior:LocalToWorld(ext.pos))
		self.portals.exterior:SetAngles(self.exterior:LocalToWorldAngles(ext.ang))
		self.portals.exterior:SetExit(self.portals.interior)
		self.portals.exterior:SetParent(self.exterior)
		self.portals.exterior.exterior = self.exterior
		self.portals.exterior.interior = self
		self.portals.exterior:Spawn()
		self.portals.exterior:Activate()
		
		self.portals.interior:SetWidth(int.width)
		self.portals.interior:SetHeight(int.height)
		self.portals.interior:SetPos(self:LocalToWorld(int.pos))
		self.portals.interior:SetAngles(self:LocalToWorldAngles(int.ang))
		self.portals.interior:SetExit(self.portals.exterior)
		self.portals.interior:SetParent(self)
		self.portals.interior.interior = self
		self.portals.interior.exterior = self.exterior
		self.portals.interior:Spawn()
		self.portals.interior:Activate()
		
		self.customportals={}
		for k,v in pairs(self.CustomPortals) do
			self.customportals[k] = {}
			local portals = self.customportals[k]
			portals.entry=ents.Create("linked_portal_door")
			portals.exit=ents.Create("linked_portal_door")
			
			portals.entry:SetWidth(v.entry.width)
			portals.entry:SetHeight(v.entry.height)
			portals.entry:SetPos(self:LocalToWorld(v.entry.pos))
			portals.entry:SetAngles(self:LocalToWorldAngles(v.entry.ang))
			portals.entry:SetExit(portals.exit)
			portals.entry:SetParent(self)
			portals.entry.exterior = self.exterior
			portals.entry.interior = self
			portals.entry.black = v.entry.black
			portals.entry:Spawn()
			portals.entry:Activate()
			
			portals.exit:SetWidth(v.exit.width)
			portals.exit:SetHeight(v.exit.height)
			portals.exit:SetPos(self:LocalToWorld(v.exit.pos))
			portals.exit:SetAngles(self:LocalToWorldAngles(v.exit.ang))
			portals.exit:SetExit(portals.entry)
			portals.exit:SetParent(self)
			portals.exit.interior = self
			portals.exit.exterior = self.exterior
			portals.exit.black = v.exit.black
			portals.exit:Spawn()
			portals.exit:Activate()
		end
	end)
else
	ENT:AddHook("Initialize","interior",function(self)
		self.contains = {}
	end)
	
	ENT:AddHook("PlayerInitialize", "portals", function(self)
		self.portals={}
		local exterior=net.ReadEntity()
		local interior=net.ReadEntity()
		if IsValid(exterior) and IsValid(interior) then
			self.portals.exterior=exterior
			self.portals.exterior.exterior=self.exterior
			self.portals.exterior.interior=self
			
			self.portals.interior=interior
			self.portals.interior.exterior=self.exterior
			self.portals.interior.interior=self
		end
		
		self.customportals={}
		local count=net.ReadInt(8)
		for i=1,count do
			local k=net.ReadString()
			self.customportals[k]={}
			local portals = self.customportals[k]
			
			portals.entry=net.ReadEntity()
			portals.entry.exterior = self.exterior
			portals.entry.interior = self
			portals.entry.black = net.ReadBool()
			
			portals.exit=net.ReadEntity()
			portals.exit.exterior = self.exterior
			portals.exit.interior = self
			portals.exit.black = net.ReadBool()
		end
	end)
	
	ENT:AddHook("ShouldDraw", "portals", function(self)
		local insideof = IsValid(wp.drawingent) and wp.drawingent.exterior and wp.drawingent.exterior.insideof==self and wp.drawingent.interior.portals.interior==wp.drawingent
		if wp.drawing and wp.drawingent==self.portals.interior and not (wp.drawingent==self.portals.interior and self.props[self.exterior]) and (not insideof) then
			return false
		end
	end)
	
	hook.Add("wp-shouldrender", "doors-portals", function(portal,exit,origin)
		local p=portal:GetParent()
		if IsValid(p) and p.DoorInterior and ((p._init and LocalPlayer().doori~=p) or (not p._init)) then
			return false
		end
	end)
	
	hook.Add("wp-predraw","doors-portals",function(portal)
		local p=portal:GetParent()
		if IsValid(p) and (p.TardisExterior or p.TardisInterior) and p._init then
			p:CallHook("PreDrawPortal")
		end
	end)
	
	hook.Add("wp-postdraw","doors-portals",function(portal)
		local p=portal:GetParent()
		if IsValid(p) and (p.TardisExterior or p.TardisInterior) and p._init then
			p:CallHook("PostDrawPortal")
		end
	end)
end