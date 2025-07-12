import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { CardAction } from "./ui/card";


export default function RpcClient() {
  return (
    <Card className="@container/card">
      <CardHeader>
        <CardTitle>rpc client</CardTitle>
      </CardHeader>
      <CardContent>
        <CardDescription>
          Connect to an evm rpc endpoint
        </CardDescription>
      </CardContent>
      <CardFooter>
        <CardAction>
          <Button>Connect</Button>
        </CardAction>
      </CardFooter>
    </Card>
  );
}
